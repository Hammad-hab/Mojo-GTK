from gi.repository import GIRepository
import json
import sys

types = set()

def get_type_string(type_info):
    """Convert a TypeInfo to a readable string"""
    try:
        tag = type_info.get_tag()
    except:
        return "void*"
  
    if tag == GIRepository.TypeTag.VOID:
        return "void"
    elif tag == GIRepository.TypeTag.BOOLEAN:
        return "boolean"
    elif tag == GIRepository.TypeTag.INT8:
        return "int8"
    elif tag == GIRepository.TypeTag.UINT8:
        return "uint8"
    elif tag == GIRepository.TypeTag.INT16:
        return "int16"
    elif tag == GIRepository.TypeTag.UINT16:
        return "uint16"
    elif tag == GIRepository.TypeTag.INT32:
        return "int32"
    elif tag == GIRepository.TypeTag.UINT32:
        return "uint32"
    elif tag == GIRepository.TypeTag.INT64:
        return "int64"
    elif tag == GIRepository.TypeTag.UINT64:
        return "uint64"
    elif tag == GIRepository.TypeTag.FLOAT:
        return "float"
    elif tag == GIRepository.TypeTag.DOUBLE:
        return "double"
    elif tag == GIRepository.TypeTag.UTF8:
        return "char*"
    elif tag == GIRepository.TypeTag.FILENAME:
        return "char*"
    elif tag == GIRepository.TypeTag.ARRAY:
        try:
            array_type = type_info.get_array_type()
            param_type = type_info.get_param_type(0)
            typestr = f"{get_type_string(param_type)}[]"
            return typestr
        except:
            return "void*[]"
    elif tag == GIRepository.TypeTag.INTERFACE:
        try:
            iface = type_info.get_interface()
            if iface is None:
                return 'GTKInterface'


            if isinstance(iface, GIRepository.EnumInfo):
                types.add(iface.get_name() + '@32')
                return iface.get_name()
            
            elif isinstance(iface, GIRepository.StructInfo):
                types.add(iface.get_name())
                
                return iface.get_name()
                # if ("TextIter" not in iface.get_name()): return iface.get_name()
                # print("It's a struct!", iface.get_name(), iface.get_size())
                # for i in range(iface.get_n_fields()):
                #     field = iface.get_field(i)
                #     print(f"  Field: {field.get_name()} {get_type_string(field.get_type_info().get_tag())}")

            if isinstance(iface, GIRepository.FlagsInfo):
                types.add(iface.get_name() + '@I')
                return iface.get_name()

            return 'GTKInterface'
        except:
            return 'GTKInterface'
    elif tag == GIRepository.TypeTag.GLIST:
        types.add('GTKType')
        return f"GTKType"
    elif tag == GIRepository.TypeTag.GTYPE:
        types.add('GTKType')
        return f"GTKType"
    elif tag == GIRepository.TypeTag.GSLIST:
        types.add('GTKType')
        return f"GTKType"
    elif tag == GIRepository.TypeTag.GHASH:
        types.add('GTKType')
        return "GTKType"
    elif tag == GIRepository.TypeTag.ERROR:
        types.add('GError')
        return "GError"
    elif tag == GIRepository.TypeTag.UNICHAR:
        return "GTKType"
    else:
        return str(tag)

def format_function_signature(func_info, class_name=None):
    """Safely extract function signature with error handling"""
    try:
        func_name = func_info.get_name()
        symbol = func_info.get_symbol()
    except:
        return None, None, None
    
    try:
        return_type_info = func_info.get_return_type()
        return_type = get_type_string(return_type_info) if return_type_info else "void"
    except:
        return_type = "void"
    
    params = {}
    
    try:
        n_args = func_info.get_n_args()
    except:
        n_args = 0

    # Always add 'self' if this is a method
    try:
        if hasattr(func_info, "get_flags"):
            flags = func_info.get_flags()
            if flags & GIRepository.FunctionInfoFlags.IS_METHOD:
                container = func_info.get_container()
                if container:
                    params["self"] = 'GTKInterface'
    except:
        pass

    # Add other parameters
    for i in range(n_args):
        try:
            arg = func_info.get_arg(i)
            arg_name = arg.get_name() or f"arg{i}"
            arg_info = arg.get_type_info()
            
            if arg_info is None:
                arg_type = "void*"
            else:
                arg_type = get_type_string(arg_info)

            direction = arg.get_direction()
            if direction == GIRepository.Direction.OUT or direction == GIRepository.Direction.INOUT:
                arg_type += "*"

            params[arg_name] = arg_type
        except:
            # Skip problematic parameters
            continue

    params_str = ", ".join(f"{t} {n}" for n, t in params.items()) if params else "void"
    signature = f"{return_type} {symbol}({params_str})"
    
    return signature, symbol, [return_type, symbol, params]


SAFE_INFO_TYPES = (
    GIRepository.FunctionInfo,
    GIRepository.ObjectInfo,
    GIRepository.InterfaceInfo,
    GIRepository.StructInfo,
    GIRepository.UnionInfo,
    GIRepository.EnumInfo,
    GIRepository.FlagsInfo,
    GIRepository.CallbackInfo,
)

# Blacklist problematic types known to cause segfaults
BLACKLIST_TYPES = {
    'AsyncReadyCallback',  # Known to cause issues
    'DestroyNotify',
    'IOFunc',
}

def is_blacklisted(name):
    """Check if a type name should be skipped"""
    return name in BLACKLIST_TYPES

def extract_all_gtk_functions():
    repo = GIRepository.Repository()
    
    try:
        # Load libraries one at a time with error handling
        namespaces = []
        
        for ns, version in [('cairo', '1.0'), ('GObject', '2.0'), ('Gio', '2.0'), ('Gtk', '4.0'), ('GLib', '2.0')]:
            try:
                print(f"Loading {ns} {version}...")
                repo.require(ns, version, 0)
                namespaces.append(ns)
                print(f"  ✓ {ns} loaded successfully")
            except Exception as e:
                print(f"  ✗ Failed to load {ns}: {e}")
                # Continue without this namespace
        
        all_functions_dict = {}
        stats = {
            'top_level_functions': 0,
            'object_methods': 0,
            'object_constructors': 0,
            'interface_methods': 0,
            'struct_methods': 0,
            'union_methods': 0,
            'callbacks': 0,
            'virtual_methods': 0,
            'static_methods': 0,
            'errors': 0
        }
        
        print("\n=== Extracting Functions with Signatures ===\n")
        
        for ns in namespaces:
            print(f"\nProcessing namespace: {ns}")
            
            try:
                n_infos = repo.get_n_infos(ns)
            except:
                print(f"  Could not get info count for {ns}, skipping")
                continue
                
            for i in range(n_infos):
                try:
                    info = repo.get_info(ns, i)
                    if info is None:
                        continue
                    if not isinstance(info, SAFE_INFO_TYPES):
                        continue
                except Exception as e:
                    stats['errors'] += 1
                    continue

                try:
                    info_name = info.get_name()
                    
                    # Skip blacklisted types
                    if is_blacklisted(info_name):
                        print(f"  Skipping blacklisted: {info_name}")
                        continue
                        
                except:
                    stats['errors'] += 1
                    continue
                
                # Process different info types with individual try-except blocks
                try:
                    if isinstance(info, GIRepository.FunctionInfo):
                        signature, symbol, raw_info = format_function_signature(info)
                        if symbol and raw_info:
                            all_functions_dict[symbol] = {
                                'rtype': raw_info[0],
                                'params': raw_info[2]
                            }
                            stats['top_level_functions'] += 1
                    
                    elif isinstance(info, GIRepository.ObjectInfo):
                        # Process methods
                        try:
                            n_methods = info.get_n_methods()
                            for j in range(n_methods):
                                try:
                                    method = info.get_method(j)
                                    signature, symbol, raw_info = format_function_signature(method, info_name)
                                    if symbol and raw_info:
                                        all_functions_dict[symbol] = {
                                            'rtype': raw_info[0],
                                            'params': raw_info[2]
                                        }
                                        flags = method.get_flags()
                                        if flags & GIRepository.FunctionInfoFlags.IS_METHOD:
                                            stats['object_methods'] += 1
                                        else:
                                            stats['static_methods'] += 1
                                except:
                                    stats['errors'] += 1
                        except:
                            pass
                        
                        # Process constructors
                        try:
                            n_constructors = info.get_n_constructors()
                            for j in range(n_constructors):
                                try:
                                    constructor = info.get_constructor(j)
                                    signature, symbol, raw_info = format_function_signature(constructor, f"{info_name}::new")
                                    if symbol and raw_info:
                                        all_functions_dict[symbol] = {
                                            'rtype': raw_info[0],
                                            'params': raw_info[2]
                                        }
                                        stats['object_constructors'] += 1
                                except:
                                    stats['errors'] += 1
                        except:
                            pass
                    
                    elif isinstance(info, GIRepository.InterfaceInfo):
                        try:
                            n_methods = info.get_n_methods()
                            for j in range(n_methods):
                                try:
                                    method = info.get_method(j)
                                    signature, symbol, raw_info = format_function_signature(method, info_name)
                                    if symbol and raw_info:
                                        all_functions_dict[symbol] = {
                                            'rtype': raw_info[0],
                                            'params': raw_info[2]
                                        }
                                        stats['interface_methods'] += 1
                                except:
                                    stats['errors'] += 1
                        except:
                            pass
                    
                    elif isinstance(info, GIRepository.StructInfo):
                        try:
                            n_methods = info.get_n_methods()
                            for j in range(n_methods):
                                try:
                                    method = info.get_method(j)
                                    signature, symbol, raw_info = format_function_signature(method, info_name)
                                    if symbol and raw_info:
                                        all_functions_dict[symbol] = {
                                            'rtype': raw_info[0],
                                            'params': raw_info[2]
                                        }
                                        stats['struct_methods'] += 1
                                except:
                                    stats['errors'] += 1
                        except:
                            pass
                    
                    elif isinstance(info, GIRepository.UnionInfo):
                        try:
                            n_methods = info.get_n_methods()
                            for j in range(n_methods):
                                try:
                                    method = info.get_method(j)
                                    signature, symbol, raw_info = format_function_signature(method, info_name)
                                    if symbol and raw_info:
                                        all_functions_dict[symbol] = {
                                            'rtype': raw_info[0],
                                            'params': raw_info[2]
                                        }
                                        stats['union_methods'] += 1
                                except:
                                    stats['errors'] += 1
                        except:
                            pass
                    
                    elif isinstance(info, GIRepository.CallbackInfo):
                        try:
                            signature, symbol, raw_info = format_function_signature(info, "Callback")
                            if symbol and raw_info:
                                all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                                stats['callbacks'] += 1
                        except:
                            stats['errors'] += 1
                
                except Exception as e:
                    stats['errors'] += 1
                    continue
                
                # Show progress
                if (i + 1) % 50 == 0:
                    print(f"  Processed {i + 1}/{n_infos} items... Found {len(all_functions_dict)} functions, {stats['errors']} errors")
        
        # Add metadata
        all_functions_dict['unique_types'] = list(types)
        all_functions_dict['_stats'] = stats
        
        # Write to file
        with open('fn.json', 'w') as f:
            json.dump(all_functions_dict, f, indent=2)
        
        print("\n=== Statistics ===")
        for key, value in stats.items():
            print(f"{key}: {value}")
        print(f"\nTotal functions extracted: {len(all_functions_dict) - 2}")  # -2 for metadata keys
        print(f"Output written to fn.json")
        
        return all_functions_dict
        
    except Exception as e:
        print(f"Fatal Error: {e}")
        import traceback
        traceback.print_exc()
        return {}

if __name__ == "__main__":
    functions = extract_all_gtk_functions()
    
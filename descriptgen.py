from gi.repository import GIRepository
import json

types = set()

def get_type_string(type_info):
    """Convert a TypeInfo to a readable string"""
    tag = type_info.get_tag()
  
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
        array_type = type_info.get_array_type()
        param_type = type_info.get_param_type(array_type)
        typestr = f"{get_type_string(param_type)}[]"
        return typestr
    elif tag == GIRepository.TypeTag.INTERFACE:
        iface = type_info.get_interface()

        if isinstance(iface, GIRepository.EnumInfo):
            types.add(iface.get_name() + '@32')
            return iface.get_name()        # or UInt32 / Int32

        if isinstance(iface, GIRepository.FlagsInfo):
            types.add(iface.get_name() + '@I')
            return iface.get_name()       # bitflags → integer

        return 'GTKInterface'
    elif tag == GIRepository.TypeTag.GLIST:
        types.add('GTKType')
        # param_type = type_info.get_param_type(0)
        return f"GTKType"
    elif tag == GIRepository.TypeTag.GTYPE:
        types.add('GTKType')
        # param_type = type_info.get_param_type(0)
        return f"GTKType"
    elif tag == GIRepository.TypeTag.GSLIST:
        types.add('GTKType')
        # param_type = type_info.get_param_type(0)
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
    func_name = func_info.get_name()
    symbol = func_info.get_symbol()
    
    return_type_info = func_info.get_return_type()
    return_type = get_type_string(return_type_info)
    
    params = {}
    n_args = func_info.get_n_args()

    # Always add 'self' if this is a method
    if hasattr(func_info, "get_flags"):
        flags = func_info.get_flags()
        if flags & GIRepository.FunctionInfoFlags.IS_METHOD:
            container = func_info.get_container()
            if container:
                params["self"] = 'GTKInterface'

    # Add other parameters
    for i in range(n_args):
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

def extract_all_gtk_functions():
    repo = GIRepository.Repository()
    
    try:
        repo.require('cairo', '1.0', 0)        
        repo.require('Gio', '2.0', 0)
        repo.require('GObject', '2.0', 0)
        repo.require('Gtk', '4.0', 0)

        
        all_functions = []
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
            'static_methods': 0
        }
        
        print("=== Extracting ALL GTK 4.0 Functions with Signatures ===\n")
        for ns in ["Gtk", "GObject", "Gio"]:
            
            n_infos = repo.get_n_infos(ns)
            for i in range(n_infos):
                try:
                    info = repo.get_info(ns, i)
                    if info is None:
                        continue
                    if not isinstance(info, SAFE_INFO_TYPES):
                        continue
                except:
                    print('failed to get proper info, bad gi')
                    continue

                try:
                    info_name = info.get_name()
                except:
                    print('failed to get name, bad gi')
                    continue
                # 1. Top-level functions
                if isinstance(info, GIRepository.FunctionInfo):
                    signature, symbol, raw_info = format_function_signature(info)
                    # all_functions.append(f"{signature}\n")
                    all_functions_dict[symbol] = {
                        'rtype': raw_info[0],
                        'params': raw_info[2]
                    }
                    stats['top_level_functions'] += 1
                
                # 2. Object/Class methods and constructors
                elif isinstance(info, GIRepository.ObjectInfo):
                    # Instance methods
                    n_methods = info.get_n_methods()
                    for j in range(n_methods):
                        method = info.get_method(j)
                        signature, symbol, raw_info = format_function_signature(method, info_name)
                        
                        flags = method.get_flags()
                        if flags & GIRepository.FunctionInfoFlags.IS_METHOD:
                            # all_functions.append(f"{signature}\n")
                            all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                            stats['object_methods'] += 1
                        else:
                            # all_functions.append(f"{signature}\n")
                            all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                            stats['static_methods'] += 1
                    
                    # Constructors
                    try:
                        n_constructors = info.get_n_constructors()
                        for j in range(n_constructors):
                            constructor = info.get_constructor(j)
                            signature, symbol, raw_info = format_function_signature(constructor, f"{info_name}::new")
                            # all_functions.append(f"{signature}\n")
                            all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                            stats['object_constructors'] += 1
                    except:
                        pass
                    
                    # Virtual methods (vfuncs)
                    try:
                        n_vfuncs = info.get_n_vfuncs()
                        for j in range(n_vfuncs):
                            vfunc = info.get_vfunc(j)
                            try:
                                signature, symbol, raw_info = format_function_signature(vfunc, f"{info_name}::vfunc")
                                # all_functions.append(f"{signature}\n")
                                all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                                stats['virtual_methods'] += 1
                            except:
                                pass
                    except:
                        pass
                
                # 3. Interface methods
                elif isinstance(info, GIRepository.InterfaceInfo):
                    n_methods = info.get_n_methods()
                    for j in range(n_methods):
                        method = info.get_method(j)
                        signature, symbol, raw_info = format_function_signature(method, info_name)
                        # all_functions.append(f"{signature}\n")
                        all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                        stats['interface_methods'] += 1
                    
                    # Virtual methods in interfaces
                    try:
                        n_vfuncs = info.get_n_vfuncs()
                        for j in range(n_vfuncs):
                            vfunc = info.get_vfunc(j)
                            try:
                                signature, symbol, raw_info = format_function_signature(vfunc, f"{info_name}::vfunc")
                                # all_functions.append(f"{signature}\n")
                                all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                                stats['virtual_methods'] += 1
                            except:
                                pass
                    except:
                        pass
                
                # 4. Struct methods
                elif isinstance(info, GIRepository.StructInfo):
                    n_methods = info.get_n_methods()
                    for j in range(n_methods):
                        method = info.get_method(j)
                        signature, symbol, raw_info = format_function_signature(method, info_name)
                        # all_functions.append(f"{signature}\n")
                        all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                        stats['struct_methods'] += 1
                
                # 5. Union methods
                elif isinstance(info, GIRepository.UnionInfo):
                    n_methods = info.get_n_methods()
                    for j in range(n_methods):
                        method = info.get_method(j)
                        signature, symbol, raw_info = format_function_signature(method, info_name)
                        # all_functions.append(f"{signature}\n")
                        all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                        stats['union_methods'] += 1
                
                # 6. Callback signatures
                elif isinstance(info, GIRepository.CallbackInfo):
                    try:
                        signature, symbol, raw_info = format_function_signature(info, "Callback")
                        # all_functions.append(f"{signature}\n  (Function pointer type)\n")
                        all_functions_dict[symbol] = {
                                    'rtype': raw_info[0],
                                    'params': raw_info[2]
                                }
                        stats['callbacks'] += 1
                    except:
                        all_functions.append(f"{info_name} (function pointer type)\n")
                        stats['callbacks'] += 1
                
                # Show progress
                if (i + 1) % 50 == 0:
                    print(f"Processed {i + 1}/{n_infos} items... Found {len(all_functions)} functions so far")
            
        # Write to file
        with open('fn.json', 'w') as f:
            # for func in all_functions:
            all_functions_dict['unique_types'] = list(types)
            f.write(json.dumps(all_functions_dict))
            return all_functions_dict
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    functions = extract_all_gtk_functions()
    function_names = functions.keys()
    mojosrc = []
    for fns in function_names:
        mojosrc.append(f'fn {fns}:\n\t')
    
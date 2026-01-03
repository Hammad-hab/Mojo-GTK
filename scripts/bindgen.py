import json

MOJO_RESERVED = ["ref", "in", 'out', "inout", "mut", "fn", "struct", "def", "len", "type", "cstringslice"]

def define_type(ptype: str, rtypemode=False):
    param_type = ptype
    if ptype.startswith('int') and not ptype.endswith('*'):
            param_type = param_type.replace('int', 'Int')
    elif ptype == "void*":
            param_type = "LegacyUnsafePointer[NoneType]"
    elif ptype.startswith("Enum-"):
            param_type = ptype.replace("Enum-", "")
    elif ptype == "void[]":
            param_type = "List[NoneType]"
    elif ptype == "void*[]":
            param_type = "List[LegacyUnsafePointer[NoneType]]"
    elif ptype.startswith('uint') and not ptype.endswith('*'):
            param_type = param_type.replace('uint', 'UInt')
    elif 'float' == ptype:
            param_type = 'Float32'
    elif 'double' == ptype:
            param_type = 'Float64'
    elif 'char*' == ptype:
            param_type = "String"
    elif 'char*[]' == ptype:
            param_type = "List[String]"
    elif ptype == 'void':
        if not rtypemode:
            param_type = 'LegacyUnsafePointer[ParameterNULL]'
        else:
            param_type = 'NoneType'
    elif 'boolean' in ptype:
            param_type = 'Bool'
    elif ptype.endswith('[]'):
            param_type = f"List[{define_type(param_type.replace('[]', ''))}]"
    elif ptype.endswith('*'):
        if 'GTKInterface' not in ptype:
            param_type = f"LegacyUnsafePointer[{define_type(param_type.replace('*', ''))}]"
        else:
            param_type = ptype.replace('*', '')
    elif 'Widget' in ptype:
            param_type = 'GTKInterface'
    
    return param_type


def generate_fn_params(params: dict[str, str]):
    param_names = params.keys()
    param_str = ""

    for pname in param_names:
        param_type = define_type(params[pname])
        if pname in MOJO_RESERVED:
            pname = f"{pname}_param"
        param_str += f'{pname}: {param_type}, '
    
    return param_str


def extract_param_names(params: dict[str, str]):
    parameters = list(params.keys())
    return parameters

def fix_parameters(params: dict[str, str], function_name:str) -> dict[str, str]:
    parameters = list(params.keys())
    nw_parameters = {}
    for p in parameters:
        if params[p].startswith('Enum-'):
            nw_parameters[p] = 'Int32'
            continue
        

        if ('def' in p):
            new_name = f'x_{p}'
            nw_parameters[new_name] = params[p]
        else:
            nw_parameters[p] = params[p]

    return nw_parameters

def extract_param_values(params: dict[str, str]):
    params = list(params.values())
    return params

def generate_function(name: str, return_type: str, params: dict[str, str]): 
    param_names = extract_param_names(params)
    # param_types = extract_param_values(params)
    
    string_types_parameters = list(filter(lambda name: 'char*' in params[name] or 'char*[]' in params[name], param_names))
    string_preprocess_ijection = ""

    if len(string_types_parameters) > 0:
        for parameter_name in string_types_parameters:
            position = (param_names).index(parameter_name)
            paramtype = params[parameter_name]

            if paramtype =='char*':
                new_parameter_name = f'cstr_{parameter_name}'
                string_preprocess_ijection += f'\n\tvar slc_{new_parameter_name} = StringSlice({parameter_name} + "\0")'
                string_preprocess_ijection += f'\n\tvar {new_parameter_name} = CStringSlice(slc_{new_parameter_name})'
                param_names[position] = new_parameter_name
                continue
                
            if paramtype =='char*[]':
                string_preprocess_ijection += f'\n\tvar nelements_{parameter_name} = len({parameter_name})'
                string_preprocess_ijection += f'\n\tvar charptr_array_{parameter_name} = LegacyUnsafePointer[LegacyUnsafePointer[c_char]].alloc(nelements_{parameter_name})'
                string_preprocess_ijection += f'\n\tfor ix in range(nelements_{parameter_name}):'
                string_preprocess_ijection += f'\n\t\tvar strelement = {parameter_name}[ix]'
                string_preprocess_ijection += f'\n\t\tvar cstr = CStringSlice(strelement + "\0")'
                string_preprocess_ijection += f'\n\t\tvar charptr = cstr.unsafe_ptr()'
                string_preprocess_ijection += f'\n\t\tcharptr_array_{parameter_name}[ix] = charptr'
                param_names[position] = f"charptr_array_{parameter_name}"



    return_type_mojo = define_type(return_type, True)
    if return_type_mojo == 'None':
        return_type_mojo = 'NoneType'
    elif return_type_mojo == 'LegacyUnsafePointer[NULL]':
        return_type_mojo = 'NoneType'
    elif return_type_mojo == 'String':
        return_type_mojo = 'LegacyUnsafePointer[c_char]'
        
    params_passed = ', '.join([(f"{name}_param" if name in MOJO_RESERVED else name) for name in param_names])
    # NOTE REPLACE, GTKINTERFACE with return_type_mojo!!!
    if return_type_mojo != 'List[String]':
        return (f"fn {name}({generate_fn_params(params)}) raises -> {return_type_mojo}:{string_preprocess_ijection}\n\treturn external_call[\"{name}\", {return_type_mojo}]({params_passed})")
    else: 
        # string list must be given a special treatment
        output_treatment = "\tvar lst = List[String]()\n\tvar i=0"
        output_treatment += "\n\twhile True:"
        output_treatment += "\n\t\tvar str_ptr = result[i]"
        output_treatment += "\n\t\tif not str_ptr:\n\t\t\tbreak"
        output_treatment += "\n\t\tvar mojo_cstring = CStringSlice(unsafe_from_ptr=str_ptr)"
        output_treatment += "\n\t\tvar mojo_string = ''"
        output_treatment += "\n\t\tmojo_cstring.write_to(mojo_string)"
        output_treatment += "\n\t\tlst.append(mojo_string)"
        output_treatment += f"\n\treturn lst^"
        return (f"fn {name}({generate_fn_params(params)}) raises -> {return_type_mojo}:{string_preprocess_ijection}\n\tvar result = external_call[\"{name}\", LegacyUnsafePointer[LegacyUnsafePointer[char]]]({params_passed})\n{output_treatment}")
    ...

def declare_legacy_ptr(type: str):
    return f'LegacyUnsafePointer[{type}]'

def declare_comptime(name: str, value: str):
    return f'comptime {name}={value}'

def declare_gtk_ptr_comptime(name: str, type: str):
    return declare_comptime(name, declare_legacy_ptr(type))

def declare_whitelisted_functions():
    WHITELIST = {
        'g_application_run': {
            'rtype': 'int32',
            'params': {
                'app': "GTKInterface",
                'argc': 'int32', 
                'argv': 'GTKType'
            }
        },
        'g_signal_connect_data': {
            'rtype': 'uint64',
            'params': {
                'instance': 'GTKInterface',
                'detailed_signal': 'char*',
                'c_handler': 'GTKType',
                'data': 'GTKType',
                'destroy_data': 'NoneType',
                'connect_flags': 'uint32'
            }
        }
    }

    functions_names = WHITELIST.keys()
    return declare_functions(functions_names, WHITELIST)

def declare_functions(functions_names, functions: dict[str]):
    mojo_bindings = '# === GTK Functions ===\n'
    for function_name in functions_names:
        try:
            if function_name == 'unique_types' or function_name == '_stats': 
                continue # unique types is not a function 
            descriptor: dict = functions[function_name]
            params: dict[str, str] = fix_parameters(descriptor['params'], function_name)
            
            rtype: str = descriptor['rtype']
            fn = generate_function(function_name, rtype, params)
            mojo_bindings += fn + '\n'
       
        except Exception as e:
            print(f'Encountered error while binding {function_name}: {e!r}')
    return mojo_bindings 

def declare_enum(name: str, descriptgen_dict: dict):
    content = f"@register_passable('trivial')\nstruct {name}:"
    fields = descriptgen_dict['values']
    for field_name, field_value in fields.items():
        if field_name == '0BSD':
            field_name = "ZERO_BSD"
        content += f"\n\tcomptime {field_name}={field_value}"
    return content

def declare_struct(name: str, descriptgen_dict: dict):
    content = f"@register_passable('trivial')\n@fieldwise_init\nstruct {name}(Copyable):"
    fields = descriptgen_dict['fields']
        
    for field_name, field_type in fields.items():
        type = define_type(field_type)
        if type.strip().startswith('List'):
            eltype = type.replace("List[", "")[0:-1]
            type = f"LegacyUnsafePointer[{eltype}]"
        if type == "String":
            type = "LegacyUnsafePointer[char]"
            
        if field_name in MOJO_RESERVED:
            field_name = f"{field_name}_param"
        content += f"\n\tvar {field_name}: {type}"

    if len(fields.keys()) == 0:
        content = f"comptime {name} = LegacyUnsafePointer[NoneType]"

    return content

with open('fn.json', 'r') as f:
    functions: dict = json.loads(f.read())
    functions_names = functions.keys()
    types: list[str] = functions['unique_types']
    comptimes = '# === GTK Types & Structs ===\n'
    # TODO: fix this after adding struct declarations
    for name, descriptjson in types.items():
        # print(descriptjson['type'])
        if descriptjson['type'] == 'Enum':
            comptimes += declare_enum(name, descriptjson) + '\n\n'
            continue

        if descriptjson['type'] == 'Struct':
            comptimes += declare_struct(name, descriptjson) + '\n\n'
            continue
        
    mojo_bindings = f"from sys.ffi import external_call, c_char, CStringSlice\ncomptime ParameterNULL=NoneType\n{comptimes}\ncomptime GTKInterface = LegacyUnsafePointer[NoneType]\ncomptime GTKType=LegacyUnsafePointer[NoneType]\ncomptime GError=LegacyUnsafePointer[NoneType]\ncomptime filename=String\ncomptime char=c_char\n"
    mojo_bindings += declare_functions(functions_names, functions)
    
    whitelisted_declarations = declare_whitelisted_functions()
    mojo_bindings += '\n' + whitelisted_declarations
    with open('gtk.mojo', 'w') as f:
        f.write(mojo_bindings)
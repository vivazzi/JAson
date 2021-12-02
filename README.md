# JSON Serialization and Deserialization in MQL

Realization of JSON protocol in mql4 / mql5. 
You can create JSON object with data of different types and run serialization and deserialization of JSON data.

This repo is fork of **JAson v. 1.12** (https://www.mql5.com/en/code/13663) with small fixes and unit tests.

## Installing

Download repo and copy `JAson/Include/JAson.mqh` folder to `<TERMINAL DIR>/MQL(4/5)/Include`

## Usage

Add `#include <JAson.mqh>` and create `CJAVal` object to work with JSON data. See simple example for easy understand:

```mql4
#include <JAson.mqh>

int OnInit(){
    CJAVal data;

    // --- simple structure ---
    data["a"] = 12;
    data["b"] = 3.14;
    data["c"] = "foo";
    data["d"] = true;

    Print(data["a"].ToInt());  // 12
    Print(data["b"].ToDbl());  // 3.14
    Print(data["c"].ToStr());  // "foo"
    Print(data["d"].ToBool());  // true

    // --- array structure ---
    data["e"].Add("bar");
    data["e"].Add(2);
    
    Print(data["e"][0].ToStr());  // "bar"
    Print(data["e"][1].ToInt());  // 2
    
    // --- nested structures ---
    // - as part of array -
    CJAVal sub_data_obj_in_list;
    sub_data_obj_in_list["k1"] = 7;
    sub_data_obj_in_list["k2"] = "baz";
    
    data["e"].Add(sub_data_obj_in_list);
    
    Print(data["e"][2]["k1"].ToInt());  // 7
    Print(data["e"][2]["k2"].ToStr());  // "baz"
    
    // - as object -
    CJAVal sub_data_obj;
    sub_data_obj["sub_c"] = "muz2";
    sub_data_obj["sub_d"] = 44;

    data["f"] = sub_data_obj;
    Print(data["f"]["sub_c"].ToStr());  // "muz2"
    Print(data["f"]["sub_d"].ToInt());  // 44
}
```

To get value from Json object, you need use methods:

- `ToInt()` for `integer` type;
- `ToDbl()` for `double` type;
- `ToStr()` for `string` type;
- `ToBool()` for `boolean` type;

For example:

```mql4
data["a"].ToInt();  // 12
data["b"].ToDbl();  // 3.14
data["c"].ToStr();  // "foo"
data["d"].ToBool();  // true
```

To create array, use `.Add()`
```mql4
data["e"].Add("bar");
data["e"].Add(2);
```

To use nested json, create other `CJAVal` object and assign to existed `CJAVal` object. Nested `CJAVal` object can be value of key or contained in array:

```mql4
CJAVal data;

// - adding as object -
CJAVal data_1;
data_1["d1_1"] = 7;
data_1["d1_2"] = "foo";

data["a"] = data_1;

// - adding as part of array -
CJAVal data_2;
data_2["d2_1"] = 1;
data_2["d2_1"] = "bar";

data["b"].Add("buz");
data["b"].Add(data_2);
data["b"].Add("muz");
```


## Serialization and Deserialization

JAson provides the serialization and deserialization:

```mql4
#include <JAson.mqh>

int OnInit(){
    string data_str;
    CJAVal data;

    data["a"] = 3.14;
    data["b"] = "foo";
    data["c"].Add("bar");
    data["c"].Add(2);
    data["c"].Add("baz");

    Print(data["b"].ToStr());  // foo
    
    data_str = data.Serialize();
    Print(data_str);  // {"a":3.14000000,"b":"foo","c":["bar",2,"baz"]}
    
    CJAVal data_2;
    data_2.Deserialize(data_str);
    
    Print(data_2["a"].ToDbl());  // 3.14
    Print(data_2["b"].ToStr());  // foo
    
    Print(data_2["c"][0].ToStr());  // bar
    Print(data_2["c"][1].ToInt());  // 2
    Print(data_2["c"][2].ToStr());  // baz
}
```

It can be useful for data saving in a file or send Json object by POST request.

POST request with Json object:

```mql4
#include <JAson.mqh>
#include <requests/requests.mqh>  // https://github.com/vivazzi/mql_requests

int OnInit(){
    CJAVal data;

    data["a"] = 7;
    data["b"] = "foo";
    
    Requests requests;
    Response response = requests.post("https://vivazzi.pro/test-request/", data.Serialize());
    
    Print(response.text);  // {"status": "OK", "method": "POST", "body": "{"a": 7, "b": "foo"}"}
    data.Deserialize(response.text);
    
    Print(data["status"].ToStr());  // "OK"
    Print(data["method"].ToStr());  // "POST"
    Print(data["body"].ToStr());  // {"a": 7, "b": "foo"}
    
    // if Json object has value of key as serialized object, you can also deserialize this value
    CJAVal data_2;
    data_2.Deserialize(data["body"].ToStr());
    Print(data_2["a"].ToInt());  // 7
    Print(data_2["b"].ToStr());  // "foo"
    
    // also you can join this Json objects to get full structure
    data["body"] = data_2;
    Print(data["body"]["a"].ToInt());
    Print(data["body"]["b"].ToStr());
}
```

In this example it has been used: [mql_requests](https://github.com/vivazzi/mql_requests) and online service [Getest](https://vivazzi.pro/en/dev/getest/) for testing GET and POST requests.

## Clear Json and check for the existence of a key

To clear `CJAVal` object, use method `Clear()`:

```mql4
#include <JAson.mqh>

int OnInit(){
    CJAVal data;
    string data_str;

    data["a"] = 3.14;
    data["b"] = "foo";
    data_str = data.Serialize();
    Print(data_str);  // "{"a":3.14000000,"b":"foo"}"

    data.Clear();
    data["c"] = 123;
    data["d"] = "bar";
    data_str = data.Serialize();
    Print(data_str);  // "{"c":123,"d":"bar"}"
}
```

So if you want to get values of "c" and "d" keys, you need:

```mql4
Print(data["c"].ToInt())  // 123
Print(data["d"].ToStr())  // "bar"
```

But if you check "a" and "b" keys, that no longer exist (or never used keys), you get initial values for key:

```mql4
// old notexistent keys
Print(data["a"].ToDbl())  // 0.0
Print(data["b"].ToStr())  // "" (empty)

// never used keys
Print(data["e"].ToStr())  // "" (empty)
```

**And this can lead to logical errors - be careful! Always use only a specific set of keys to avoid logical error!**

If you use Json, that can be cleaned up, and you use different keys, you can check type of keys. JAson library define next types:

- `jtUNDEF`, if key is undefined
- `jtNULL` for `NULL`
- `jtBOOL` for `boolean`
- `jtINT` for `int`
- `jtDBL` for `double`
- `jtSTR` for `string`
- `jtARRAY` for `array`
- `jtOB` for `obj`

Then in example above:

```mql4
// old notexistent keys
Print(data["a"].ToDbl());  // 0.0
Print(data["a"].m_type);  // jtUNDEF
Print(data["b"].ToStr());  // ""
Print(data["b"].m_type);  // jtUNDEF

// current keys
Print(data["c"].ToInt());  // 123
Print(data["c"].m_type);  // jtINT
Print(data["d"].ToStr());  // "bar"
Print(data["d"].m_type);  // jtSTR

// never used keys
Print(data["e"].ToStr());  // ""
Print(data["e"].m_type);  // jtUNDEF
```

So you can compare key type with `jtUNDEF`, if you want to check for the existence of a key:

```mql4
#include <JAson.mqh>

int OnInit(){
    CJAVal data;

    data["a"] = 3.14;

    data.Clear();
    data["c"] = 123;
    
    if (data["a"].m_type == jtUNDEF) {
        // do something
    } else {
        // else do something
    }
}
```

## API

#### Constructors:

- `CJAVal data;` - Creates `CJAVal` (Json) object.  
- `CJAVal data(CJAVal* aparent, enJAType atype);` - Creates `CJAVal` object with specified type. `aparent` - parent for created `CJAVal` object (use `NULL` if no parent). `atype` - type of `CJAVal` object, available types: `jtUNDEF`, `jtNULL`, `jtBOOL`, `jtINT`, `jtDBL`, `jtSTR`, `jtARRAY`, `jtOBJ`.  
- `CJAVal data(const double a, int aprec=-100);` - Creates `CJAVal` object of double type of specified precision.   


#### Assigment methods:

- `data[key] = some_val;` - Adds `some_val` (int, double, string or another `CJAVal`) to data with `key` key.  
- `data[key].Add(other_data);` - Adds `other_data` (int, double, string or other CJAVal) to `key` array.  
- `data[key].Add(const double a, int aprec=-2);` - Adds `a` of double type with specified precision to `key` array.  


#### Serialization and deserialization:

- `data.Serialize();` - Convert `CJAVal` object to string.  
- `data.Deserialize(string js, int acp=CP_ACP);` - Convert `js` string to `CJAVal` object. `data` gets result. `acp` - code page for deserialization. 


#### Other helper methods:

- `data.Clear(enJAType jt=jtUNDEF, bool savekey=false);` - Clears `CJAVal` object. `jt`- sets specified type of `CJAVal` object.  `savekey` - if `true`, values of all keys will be keys will be cleared, else all keys and values will be cleared.  
- `data.Size();` - Gets size of `CJAVal` object.


### Precision rules of double type for m_prec parameter

- If the `m_prec` value is in the range from 0 to 16, then a string representation of the number with the specified number of decimal places will be obtained.  
- If the `m_prec` value is in the range from -1 to -16, then the string representation of the number in scientific format with the specified number of decimal places will be obtained.  
- In all other cases, the string representation of the number will contain 8 decimal places.  

## Run tests

1. Copy `JAson/Experts/TestJAson.mq4` to `<TERMINAL DIR>/MQL(4/5)/Experts`
2. Compile `TestJAson.mq4` and run `TestJAson.ex4` in terminal in a window of any trading pair.
3. Look test result in `<TERMINAL DIR>/Files/TestJAson_unit_test_log.txt`

## Fixes of fork

1. Wrapped lines with `Print` with `DEBUG` define condition `#ifdef DEBUG Print(m_key+" "+string(__LINE__));#endif` to void extra info in terminal journal.
2. Translated comments in library.
3. Added unit tests.
3. Expanded body of some functions for readability.
4. Fixed bugs (with assignment of nested `JAson` object and others).

# CONTRIBUTING

To reporting bugs or suggest improvements, please use the [issue tracker](https://github.com/vivazzi/JAson/issues).

Thank you very much, that you would like to contribute to **JAson**. Thanks to the [present, past and future contributors](https://github.com/vivazzi/JAson/blob/main/CONTRIBUTORS.md).

If you think you have discovered a security issue in code, please do not create issue or raise it in any public forum until we have had a chance to deal with it.
**For security issues use security@vuspace.pro**


# LINKS

- Report bugs and suggest improvements:
    - https://www.mql5.com/en/code/13663 (recommended)
    - https://github.com/vivazzi/JAson/issues
    
# LICENCE

Copyright © 2021 Alexey Sergeev and [contributors](https://github.com/vivazzi/JAson/blob/main/CONTRIBUTORS.md).

Small fixes and unit tests: Artem Maltsev.

MIT licensed.

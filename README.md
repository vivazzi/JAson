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

    // simple structure
    data["a"] = 12;
    data["b"] = 3.14;
    data["b"] = "foo";
    data["d"] = true;

    Print(data["a"].ToInt());  // 12
    Print(data["b"].ToDbl());  // 3.14
    Print(data["c"].ToStr());  // "foo"
    Print(data["d"].ToBool());  // true

    // array structure
    data["e"].Add("bar");
    data["e"].Add(2);
    
    Print(data["e"][0].ToStr());  // "bar"
    Print(data["e"][1].ToInt());  // 2
    
    // nested structure
    CJAVal nested_data;
    nested_data["k1"] = 7;
    nested_data["k2"] = "baz";
    
    data["e"].Add(nested_data);
    
    Print(data["e"][2]["k1"].ToInt());  // 7
    Print(data["e"][2]["k2"].ToStr());  // "baz"
}
```

> **WARNING**: At this moment JAson has a bug with assignment of CJAVal instance of Object type to other CJAVal instance:
> ```mql4
> #include <JAson.mqh>
> 
> int OnInit(){
>     CJAVal data;
> 
>     // simple structure
>     data["a"] = 12;
> 
>     // nested structure
>     CJAVal nested_data;
>     nested_data["k1"] = 7;
>     nested_data["k2"] = "baz";
>     
>     data["b"] = nested_data;
>     
>     Print(data["b"]["k1"].ToInt());  // will be 0 instead of 7
>     Print(data["b"]["k2"].ToStr());  // will be "" instead of "baz"
>     Print(data.Serialize());
> }
> ```
> See issue: https://github.com/vivazzi/JAson/issues/1


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

CJAVal data_1;
data_1["k1"] = 7;
data_1["k2"] = "foo";

data["a"] = data_1;

CJAVal data_2;
data_2["a"] = 1;
data_2["b"] = "bar";

data["b"].Add("buz");
data["b"].Add(data_2);
```


## Serialization and Deserialization

JAson provide the serialization and deserialization:

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
}
```

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

But if you check "c" and "d" keys, that no longer exist (or never used keys), you get initial values for key:

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

## Run tests

1. Copy `JAson/Experts/TestJAson.mq4` to `<TERMINAL DIR>/MQL(4/5)/Experts`
2. Compile `TestJAson.mq4` and run `TestJAson.ex4` in terminal in a window of any trading pair.
3. Look test result in `<TERMINAL DIR>/Files/TestJAson_unit_test_log.txt`

## Fixes of fork

1. Wrapped lines with `Print` with `DEBUG` define condition `#ifdef DEBUG Print(m_key+" "+string(__LINE__));#endif` to void extra info in terminal journal.
2. Translated comments in library.
3. Added unit tests.

# CONTRIBUTING

To reporting bugs or suggest improvements, please use the [issue tracker](https://github.com/vivazzi/jason/issues).

Thank you very much, that you would like to contribute to JAson. Thanks to the [present, past and future contributors](https://github.com/vivazzi/jason/contributors).

If you think you have discovered a security issue in code, please do not create issue or raise it in any public forum until we have had a chance to deal with it.
**For security issues use security@vuspace.pro**


# LINKS

- Report bugs and suggest improvements:
    - https://www.mql5.com/en/code/13663 (recommended)
    - https://github.com/vivazzi/jason/issues
    
# LICENCE

Copyright © 2021 Alexey Sergeev.

Small fixes and unit tests: Artem Maltsev.

MIT licensed.
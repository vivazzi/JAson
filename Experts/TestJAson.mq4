#property copyright "Copyright © 2019-2021 Artem Maltsev (Vivazzi)"
#property link      "https://vivazzi.pro"
#property description   "Tests for JAson"
#property strict


#include <JAson.mqh>
#include <unit_test/unit_test.mqh>
#include <requests/requests.mqh>


class TestJAson: public TestCase {
public:
    void test_simple() {
        CJAVal data;

        data["a"] = 3.14;
        data["b"] = "foo";
        data["c"].Add("bar");
        data["c"].Add(2);
        data["c"].Add("baz");

        assert_equal(data["b"].ToStr(), "foo");

        string data_str = data.Serialize();  // {"a":3.14000000,"b":"foo","c":["bar",2,"baz"]}
        assert_equal(data_str, "{\"a\":3.14000000,\"b\":\"foo\",\"c\":[\"bar\",2,\"baz\"]}");

        CJAVal data_2;
        data_2.Deserialize(data_str);
        assert_equal(data_2["a"].ToDbl(), 3.14);
        assert_equal(data_2["b"].ToStr(), "foo");

        assert_equal(data_2["c"][0].ToStr(), "bar");
        assert_equal(data_2["c"][1].ToInt(), 2);
        assert_equal(data_2["c"][2].ToStr(), "baz");
    }

    void test_complex() {
        CJAVal data;

        data["a"] = 3.14;
        data["b"] = "foo";
        data["c"].Add("bar");
        data["c"].Add(2);
        data["c"].Add("baz");

        CJAVal sub_data_list;
        sub_data_list.Add(1);
        sub_data_list.Add("bar");

        CJAVal sub_data_obj_in_list;
        sub_data_obj_in_list["sub_a"] = "muz";
        sub_data_obj_in_list["sub_b"] = 22;

        data["c"].Add(sub_data_list);
        data["c"].Add(sub_data_obj_in_list);

        CJAVal sub_data_obj;
        sub_data_obj["sub_c"] = "muz2";
        sub_data_obj["sub_d"] = 44;

        data["d"] = sub_data_obj;

        string serialized_data_str = data.Serialize();  // {"a":3.14000000,"b":"foo","c":["bar",2,"baz",[1,"bar"],{"sub_a":"muz","sub_b":22}],"d":{"sub_c":"muz2","sub_d":44}
        string data_str = "{\"a\":3.14000000,\"b\":\"foo\",\"c\":[\"bar\",2,\"baz\",[1,\"bar\"],{\"sub_a\":\"muz\",\"sub_b\":22}],\"d\":{\"sub_c\":\"muz2\",\"sub_d\":44}}";
        assert_equal(serialized_data_str, data_str);

        CJAVal data_2;
        data_2.Deserialize(data_str);
        assert_equal(data_2["a"].ToDbl(), 3.14);
        assert_equal(data_2["b"].ToStr(), "foo");

        assert_equal(data_2["c"][0].ToStr(), "bar");
        assert_equal(data_2["c"][1].ToInt(), 2);
        assert_equal(data_2["c"][2].ToStr(), "baz");
        assert_equal(data_2["c"][3][0].ToInt(), 1);
        assert_equal(data_2["c"][3][1].ToStr(), "bar");
        assert_equal(data_2["c"][4]["sub_a"].ToStr(), "muz");
        assert_equal(data_2["c"][4]["sub_b"].ToInt(), 22);

        assert_equal(data_2["d"]["sub_c"].ToStr(), "muz2");
        assert_equal(data_2["d"]["sub_d"].ToInt(), 44);
    }

    void test_deserializing() {
        CJAVal data;

        data["a"] = 3.14;
        data["b"] = "foo";

        string data_str = data.Serialize();

        CJAVal data_2;
        bool deserialized;
        deserialized = data_2.Deserialize(data_str);
        assert_equal(deserialized, true);

        data_str = "\"a\":1,\"b\":\"foo\"";  // "a":1,"b":"foo" - you can deserialize without parentheses
        deserialized = data_2.Deserialize(data_str);
        assert_equal(deserialized, true);

        // bad data
        string bad_data_str;
        bad_data_str = "{\"a\":1,\"b\":foo\"}";  // {"a":1,"b":foo"} - missing: "
        deserialized = data_2.Deserialize(bad_data_str);
        assert_equal(deserialized, false);

        bad_data_str = "{\"a\":,\"b\":\"foo\"}";  // {"a":,"b":"foo"} - missing: value
        deserialized = data_2.Deserialize(bad_data_str);
        assert_equal(deserialized, false);

        bad_data_str = "{\"a\":1,\"b\":[\"foo\", \"bar\"}";  // {"a":1,"b":["foo", "bar"} - missing: [
        deserialized = data_2.Deserialize(bad_data_str);
        assert_equal(deserialized, false);
    }

    void test_clear() {
        CJAVal data;
        string data_str;

        data["a"] = 3.14;
        data["b"] = "foo";
        data_str = data.Serialize();
        assert_equal(data_str, "{\"a\":3.14000000,\"b\":\"foo\"}");

        data.Clear();
        data["c"] = 123;
        data["d"] = "bar";
        data_str = data.Serialize();
        assert_equal(data_str, "{\"c\":123,\"d\":\"bar\"}");

        // old notexistent keys
        assert_equal(data["a"].ToDbl(), 0.0);
        assert_equal(data["a"].m_type, jtUNDEF);
        assert_equal(data["b"].ToStr(), "");
        assert_equal(data["b"].m_type, jtUNDEF);

        // current keys
        assert_equal(data["c"].ToInt(), 123);
        assert_equal(data["c"].m_type, jtINT);
        assert_equal(data["d"].ToStr(), "bar");
        assert_equal(data["d"].m_type, jtSTR);

        // never used keys
        assert_equal(data["e"].ToStr(), "");
        assert_equal(data["e"].m_type, jtUNDEF);
    }

    void test_json_with_requests() {
        CJAVal data;

        data["a"] = 7;
        data["b"] = "foo";

        Requests requests;
        Response response = requests.post("https://vivazzi.pro/test-request/?json=true", data.Serialize());

        assert_equal(response.text, "{\"status\": \"OK\", \"method\": \"POST\", \"query_string\": \"json=true\", \"body\": \"{\\\"a\\\":7,\\\"b\\\":\\\"foo\\\"}\"}");
        data.Deserialize(response.text);

        assert_equal(data["status"].ToStr(), "OK");
        assert_equal(data["method"].ToStr(), "POST");
        assert_equal(data["query_string"].ToStr(), "json=true");
        assert_equal(data["body"].ToStr(), "{\"a\":7,\"b\":\"foo\"}");


        // if Json object has value of key as serialized object, you can also deserialize this value
        CJAVal body_obj;
        body_obj.Deserialize(data["body"].ToStr());
        assert_equal(body_obj["a"].ToInt(), 7);
        assert_equal(body_obj["b"].ToStr(), "foo");

        // also you can join this Json objects to get full structure
        data["body_obj"] = body_obj;
//        Print(data.Serialize());
//        Print(data[""]["a"].ToInt());
        assert_equal(data["body_obj"]["a"].ToInt(), 7);
    }

    void declare_tests() {
        test_simple();
        test_complex();
        test_deserializing();
        test_clear();
        test_json_with_requests();
    }

};

int OnInit(){
    TestJAson test_jason;
    test_jason.run();

	return(INIT_SUCCEEDED);
}
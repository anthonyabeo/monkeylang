module objekt.objekt_test;

import std.stdio;

import objekt.objekt;

unittest {
    testStringHashKey();
}

///
void testStringHashKey() {
    auto hello1 = new String("Hello World");
    auto hello2 = new String("Hello World");
    auto diff1 = new String("My name is johnny");
    auto diff2 = new String("My name is johnny");

    if(hello1.hashKey() != hello2.hashKey()) {
        stderr.writeln("strings with same content have different hash keys");
        assert(hello1.hashKey() == hello2.hashKey());
    }

    if(diff1.hashKey() != diff2.hashKey()) {
        stderr.writeln("strings with same content have different hash keys");
        assert(diff1.hashKey() == diff2.hashKey());
    }

    if(hello1.hashKey() == diff1.hashKey()) {
        stderr.writeln("strings with different content have same hash keys");
        assert(hello1.hashKey() != diff1.hashKey());
    }
}
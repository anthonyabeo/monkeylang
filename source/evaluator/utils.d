module evaluator.utils;

import std.string;

import objekt.objekt;

///
Err newError(T...) (string fmt, T args) {
    return new Err(format(fmt, args));
}

module vm.frame;

import code.code;
import objekt.objekt;


/+++/
class Frame {
    CompiledFunction fn;    /// funtion to be executed
    int ip;              /// instruction ptr;

    /+++/
    this(CompiledFunction fn) {
        this.fn = fn;
        this.ip = -1;
    }

    /+++/
    Instructions instructions() {
        return this.fn.instructions;
    }
}
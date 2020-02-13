module vm.frame;

import code.code;
import objekt.objekt;


/+++/
class Frame {
    Closure cl;    /// funtion to be executed
    int ip;                 /// instruction ptr;
    int basePtr;            /// base ptr;

    /+++/
    this(Closure cl, int basePtr) {
        this.cl = cl;
        this.ip = -1;
        this.basePtr = basePtr;
    }

    /+++/
    Instructions instructions() {
        return this.cl.fn.instructions;
    }
}
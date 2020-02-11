module vm.frame;

import objekt.objekt;
import code.code;


/+++/
class Frame {
    CompiledFunction fn;    /// instructions
    int ip;              /// instruction ptr

    /+++/
    this(CompiledFunction fn) {
        this.fn = fn;
        this.ip = -1;
    }

    ///
    @property
    Instructions instructions() {
        return this.fn.instructions;
    }
}
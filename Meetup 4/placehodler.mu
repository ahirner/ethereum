exit compile {
  this.store[this.caller()]=this.store[this.caller()]+this.value()
  if this.dataSize() == 96 {
    var cmd = this.data [0]
    var vol = this.data [1]
    var dest= this.data [2]
    var balance = this.store[this.caller()]
    
    if (vol <= balance) {
    
      if (cmd == "withdraw") {
        transact (dest, 10000, vol, nil)
      }
      if (cmd == "send") {
        this.store[dest]=this.store[dest]+vol
      }
     
      this.store[this.caller()]=this.store[this.caller()]-vol
    }
  }
}

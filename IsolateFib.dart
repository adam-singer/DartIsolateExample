// This uses Isolate.heavy(), so its best to run on dart_bin
// ~/dart_bleeding/dart/out/Debug_ia32/dart_bin ./IsolateFib.dart 

class FibInfo {
  num fibIndex;
  num fibValue;
  FibInfo([this.fibIndex=0,this.fibValue=0]);
}

class FibCommand {
  static final INIT = "init";
  static final CALCULATE = "calculate";
}

class IsolateFib {
  final Map<String, SendPort> ports;
  final ReceivePort isolateFibPort;
  
  IsolateFib() : ports = new Map(), isolateFibPort = new ReceivePort() {}
  
  void createIsolateFibWorker(String name) {
    new IsolateFibWorker().spawn().then((SendPort port){
      var message = { 
                     "id" : FibCommand.INIT,
                      "args" : [name,isolateFibPort]
      };
      port.call(message);
      ports[name] = port;
    });
  }
  
  void runIsolateFibWorker(String name, int fibNumber) {
    var message = {
                   "id" : FibCommand.CALCULATE,
                   "args" : [fibNumber]
    };
   
    ports[name].call(message).receive((var m, SendPort){
      print("${name}: calculated fibIndex=${m.fibIndex},fibValue=${m.fibValue}");
    });
  }
  
}


fib(x) {  
  if (x<=0) {
    return 0;
  }
  else if (x==1) {
    return 1;
  }
  else {
    return fib(x-1) + fib(x-2);
  }    
}

class PromiseFib {
  Promise<FibInfo> promiseFibInfo;
  PromiseFib() {
    promiseFibInfo = new Promise<FibInfo>();
    promiseFibInfo.then((FibInfo x) {
      x.fibValue = fib(x.fibIndex);
    });
  }
  
  void run(FibInfo fibInfo) {
    promiseFibInfo.complete(fibInfo);
  }
}

class IsolateFibWorker extends Isolate {
  
  String isolateName;
  SendPort isolateFibPort;
  
  IsolateFibWorker() : super.heavy() {}
  
  void main() {
    this.port.receive((message, SendPort replyTo) {
      switch(message["id"]) {
        case FibCommand.INIT:
          init(message["args"][0], message["args"][1]);
          break;
      
        case FibCommand.CALCULATE:
          run(message["args"][0], replyTo);
          break;
      }
    });
  }
  
  void init(String name, SendPort port) {
    this.isolateName = name;
    this.isolateFibPort = port;
  }
  
  void run(int fibNumber, SendPort replyTo) {
    FibInfo fibInfo = new FibInfo(fibNumber);
    PromiseFib promiseFib = new PromiseFib();
    promiseFib.promiseFibInfo.addCompleteHandler((FibInfo x){
      print(isolateName + ": calculation complete");
      replyTo.send(x);
    });
    promiseFib.run(fibInfo);
  }
}

void main() {
  String w = "worker";
  
  IsolateFib isoFib = new IsolateFib();
  print("isoFib created");
  
  isoFib.createIsolateFibWorker(w+"1");
  print("isoFib created fib worker1");
  isoFib.runIsolateFibWorker(w+"1", 5);
  
  isoFib.createIsolateFibWorker(w+"2");
  print("isoFib created fib worker2");
  isoFib.runIsolateFibWorker(w+"2", 150);
  
  isoFib.createIsolateFibWorker(w+"3");
  print("isoFib created fib worker3");
  isoFib.runIsolateFibWorker(w+"3", 10);
  
  isoFib.createIsolateFibWorker(w+"4");
  print("isoFib created fib worker4");
  isoFib.runIsolateFibWorker(w+"4", 20);
}
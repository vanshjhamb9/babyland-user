import 'dart:developer';

pt(String message,{String? name}){
  // if(kDebugMode) {
    log(message,name: "---------${name ?? ""}--------->");
  // }
}
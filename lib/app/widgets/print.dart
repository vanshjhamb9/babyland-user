import 'dart:developer';
import 'package:flutter/foundation.dart';

pt(String message,{String? name}){
  // if(kDebugMode) {
    log(message,name: "---------${name ?? ""}--------->");
  // }
}
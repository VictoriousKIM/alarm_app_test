package com.example.alarm_app_test

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Field

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm_app/sounds"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRawSoundFiles" -> {
                    try {
                        val soundFiles = getRawSoundFiles()
                        result.success(soundFiles)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get raw sound files", e.message)
                    }
                }
                "getPackageName" -> {
                    try {
                        result.success(context.packageName)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get package name", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // raw 디렉토리의 파일 목록 가져오기
    private fun getRawSoundFiles(): List<String> {
        val soundFiles = mutableListOf<String>()
        
        try {
            // R.raw 클래스의 필드 가져오기
            val rawClass = Class.forName("${applicationContext.packageName}.R\$raw")
            val fields = rawClass.fields
            
            // 각 필드는 raw 디렉토리의 리소스를 나타냄
            for (field in fields) {
                soundFiles.add(field.name)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return soundFiles
    }
}

# Pin java versions
common --java_language_version=17
common --java_runtime_version=remotejdk_17
common --tool_java_language_version=17
common --tool_java_runtime_version=remotejdk_17
# Repository rules: don't depend on a JAVA_HOME pointing at a system JDK
# see https://github.com/bazelbuild/rules_jvm_external/issues/445
common --repo_env=JAVA_HOME=../bazel_tools/jdk

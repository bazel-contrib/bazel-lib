@set dir=%~dp0
@set dir=%dir:\=/%
@echo %BAZEL_SH% -c "%dir%test_with_run.sh %*"
@%BAZEL_SH% -c "%dir%test_with_run.sh %*"
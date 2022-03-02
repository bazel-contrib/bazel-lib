# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Rule and corresponding provider that joins a label pointing to a TreeArtifact
with a path nested within that directory
"""

load(
    "//lib/private:directory_path.bzl",
    _DirectoryPathInfo = "DirectoryPathInfo",
    _directory_path = "directory_path",
    _make_directory_path = "make_directory_path",
    _make_directory_paths = "make_directory_paths",
)

directory_path = _directory_path
make_directory_path = _make_directory_path
make_directory_paths = _make_directory_paths
DirectoryPathInfo = _DirectoryPathInfo

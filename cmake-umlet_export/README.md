# Using CMake to export UMLet diagrams

UMLet (see [umlet.com](https://www.umlet.com)) is a graphical tool for creating UML diagrams. The diagrams are stored in XML-files using the extension `*.uxf`. UMLet is capable of converting these to several image types.

CMake needs to know how to run UMLet. Because UMLet is a Java application, the first step is to enable CMake to use Java. The second step is to find UMLet's jar-file. In the current state of this CMakeLists.txt the jar-file is required to reside in a location pointed to by the `PATH` environment variable, i.e. the UMLet install directory should be appended to `PATH`. The last step would be tell UMLet to which files to export to which format and which location.

> **todo** Allow for manually setting the path to the UMLet directory.


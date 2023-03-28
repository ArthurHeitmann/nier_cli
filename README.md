# Nier CLI

An all in one tool for converting all sorts of files from Nier Automata.

## Supported files

|            | Extracting | Repacking |
|------------|------------|-----------|
| CPK        | ✅          | ❌         |
| DAT        | ✅          | ✅         |
| PAK        | ✅          | ✅         |
| BXM        | ✅          | ✅         |
| YAX        | ✅          | ✅         |
| Ruby (BIN) | ✅          | ✅         |
| WTA        | ✅          | ❌         |
| WTP        | ✅          | ❌         |
| BNK        | ✅          | ✅         |
| WEM/WAV    | ✅          | ✅         |
| .Z         | ✅          | ❌         |

## Download

Download the latest version from the [releases section](https://github.com/ArthurHeitmann/nier_cli/releases)

## Usage

### Drag & Drop

https://user-images.githubusercontent.com/37270165/218335861-c6fd2c0c-9b28-49dc-a124-1919314af7a8.mp4

### Command line

#### Examples

Unpack CPK file to specific destination
```bat
nier_cli "G:\Games\steamapps\common\NieRAutomata\data\data100.cpk" -o "D:\modding\na\data100.cpk_unpacked"
```

Unpack several CPK files and also unpack all DAT files and all their children
```bat
nier_cli "G:\Games\steamapps\common\NieRAutomata\data\data015.cpk" "G:\Games\steamapps\common\NieRAutomata\data\data100.cpk" --autoExtractChildren
```

#### Full explanation

```
nier_cli <input1> [input2] [input...] [options]
  or
nier_cli <input> -o <output> [options]

Options:
-o, --output                 Output file or folder

Extraction Options:
    --folder                 Extract all files in a folder
-r, --recursive              Extract all files in a folder and all subfolders
    --autoExtractChildren    When unpacking DAT, CPK, PAK, etc. files automatically process all extracted files

WAV to WEM Conversion Options:
    --wwiseCli               Path to WwiseCLI.exe
    --wemBGM                 Use music/BGM settings
    --wemVolNorm             Enable volume normalization

Extraction filters:
    --CPK                    Only extract CPK files
    --DAT                    Only extract DAT files
    --PAK                    Only extract PAK files
    --BXM                    Only extract BXM files
    --YAX                    Only extract YAX files
    --RUBY                   Only extract RUBY files
    --WTA                    Only extract WTA files
    --WTP                    Only extract WTP files
    --BNK                    Only extract BNK files
    --WEM                    Only extract WEM files
-h, --help                   Print this help message
```

### Config files

You can also save your most used parameters in the `config.txt` file. Each line is one parameter. You can find examples and presets in the `configExamples\config_XYZ.txt` files.

## Building (for developers)

0. Install the Dart SDK (it's already included in the Flutter SDK)

1. Download git submodules with
	```bat
	git submodule update --init
	```

3. Update dependencies with
   ```bat
   flutter pub get
   ```

4. Build with
	```bat
	dart compile exe bin\nier_cli.dart 
	```

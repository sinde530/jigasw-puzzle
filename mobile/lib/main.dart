import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PuzzleApp());
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ImageSelectionScreen(),
    );
  }
}

class ImageSelectionScreen extends StatelessWidget {
  const ImageSelectionScreen({super.key});

  final List<String> images = const [
    'assets/image1.jpeg',
    'assets/image2.png',
    'assets/image3.jpeg',
  ];

  void _navigateToPuzzle(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleSizeSelectionScreen(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이미지 선택')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _navigateToPuzzle(context, images[index]),
            child: Card(
              elevation: 4,
              child: Image.asset(images[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class PuzzleSizeSelectionScreen extends StatelessWidget {
  final String imagePath;
  const PuzzleSizeSelectionScreen({super.key, required this.imagePath});

  final List<int> puzzleSizes = const [3, 4, 5];

  void _startPuzzle(BuildContext context, int size) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PuzzleScreen(imagePath: imagePath, gridSize: size),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('퍼즐 크기 선택')),
      body: ListView(
        children: puzzleSizes.map((size) {
          return ListTile(
            title: Text('$size x $size 퍼즐'),
            onTap: () => _startPuzzle(context, size),
          );
        }).toList(),
      ),
    );
  }
}

class PuzzleScreen extends StatefulWidget {
  final String imagePath;
  final int gridSize;

  const PuzzleScreen(
      {super.key, required this.imagePath, required this.gridSize});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  List<ui.Image>? puzzlePieces;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load(widget.imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final List<ui.Image> pieces =
        await splitImage(frameInfo.image, widget.gridSize);

    setState(() {
      puzzlePieces = pieces;
    });
  }

  Future<List<ui.Image>> splitImage(ui.Image image, int gridSize) async {
    final List<ui.Image> pieces = [];
    final int pieceWidth = (image.width / gridSize).floor();
    final int pieceHeight = (image.height / gridSize).floor();

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);

        final Rect srcRect = Rect.fromLTWH(
          x * pieceWidth.toDouble(),
          y * pieceHeight.toDouble(),
          pieceWidth.toDouble(),
          pieceHeight.toDouble(),
        );

        final Rect dstRect =
            Rect.fromLTWH(0, 0, pieceWidth.toDouble(), pieceHeight.toDouble());

        canvas.drawImageRect(image, srcRect, dstRect, Paint());

        final ui.Image pieceImage =
            await recorder.endRecording().toImage(pieceWidth, pieceHeight);
        pieces.add(pieceImage);
      }
    }

    return pieces;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.gridSize} x ${widget.gridSize} 퍼즐')),
      body: puzzlePieces == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.gridSize,
                crossAxisSpacing: 0.4,
                mainAxisSpacing: 0.4,
              ),
              itemCount: puzzlePieces!.length,
              itemBuilder: (context, index) {
                return PuzzlePiece(image: puzzlePieces![index]);
              },
            ),
    );
  }
}

class PuzzlePiece extends StatelessWidget {
  final ui.Image image;

  const PuzzlePiece({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _imageToWidget(image),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data!;
        } else {
          return Container(color: Colors.grey);
        }
      },
    );
  }

  Future<Widget> _imageToWidget(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return Image.memory(uint8List, fit: BoxFit.cover);
  }
}

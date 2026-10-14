import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'engine/metronome_engine.dart';
import 'widgets/pulse_visualizer.dart';
import 'widgets/matrix_visualizer.dart';
import 'widgets/border_glow_visualizer.dart';
import 'widgets/radial_rings.visualizer.dart';
import 'widgets/true_oscilloscope_visualizer.dart';
import 'widgets/rhythmic_bars_visualizer.dart';
import 'widgets/pong_visualizer.dart';

class AppTheme {
  final Color primary;
  final Color secondary;

  AppTheme({required this.primary, required this.secondary});
}

void main() {
  runApp(const MetronomeApp());
}

class MetronomeApp extends StatelessWidget {
  const MetronomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metronome',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.purple[300],
      ),
      home: const MetronomeScreen(),
    );
  }
}

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  int bpm = 120;
  bool isPlaying = false;
  int beatsPerMeasure = 4;
  int noteValue = 4;
  List<MeasureBlock> customSequence = [];
  int currentVisualBeat = 0;
  int visualBeatsPerMeasure = 4;
  String selectedVisualizer = 'Matrix';
  int visualNoteValue = 4;
  int currentSequenceIndex = -1;
  final ScrollController _sequenceScrollController = ScrollController();
  String selectedSound = 'Default';
  final List<String> _availableSounds = [
    'Default',
    'Cowbell',
    'Whistle',
    'Block',
    'Bit',
    'Can',
    'Clap',
    'PracticePad',
  ];
  final PageController _pageController = PageController(initialPage: 0);

  AppTheme currentTheme = AppTheme(
    primary: Colors.deepPurpleAccent,
    secondary: Colors.purple[300]!,
  );

  final List<AppTheme> _availableThemes = [
    // 1. Void Purple
    AppTheme(primary: Colors.purple[300]!, secondary: Colors.deepPurpleAccent),
    // 2. Laser Red
    AppTheme(
      primary: const Color(0xFFFF3333),
      secondary: const Color(0xFF990000),
    ),
    // 3. Electric Blue
    AppTheme(primary: Colors.cyanAccent, secondary: Colors.blueAccent),
    // 4. Amber
    AppTheme(primary: Colors.amberAccent, secondary: Colors.orange[700]!),
  ];

  final MetronomeEngine _engine = MetronomeEngine();

  void _applySequence() {
    if (customSequence.isEmpty) {
      _engine.setSequence([]);
      _engine.setTimeSignature(beatsPerMeasure, noteValue);

      if (!isPlaying) {
        currentSequenceIndex = -1;
        visualNoteValue = noteValue;
      }
    } else {
      List<int> flatSequence = [];
      for (var block in customSequence) {
        flatSequence.add(block.numerator);
        flatSequence.add(block.denominator);
      }
      _engine.setSequence(flatSequence);

      if (!isPlaying) {
        currentSequenceIndex = -1;
        visualNoteValue = customSequence[0].denominator;
      } else {
        if (currentSequenceIndex >= customSequence.length) {
          currentSequenceIndex = customSequence.length - 1;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _engine.init();
    _loadAudioAssets();

    _engine.setBeatListener((currentBeat, beatsPerMeasure, isAccent) {
      setState(() {
        if (currentBeat == 0) {
          if (customSequence.isNotEmpty) {
            currentSequenceIndex =
                (currentSequenceIndex + 1) % customSequence.length;
            visualNoteValue = customSequence[currentSequenceIndex].denominator;

            if (isPlaying) {
              _scrollToCurrentSequence();
            }
          } else {
            visualNoteValue = noteValue;
          }
        }
        currentVisualBeat = currentBeat;
        visualBeatsPerMeasure = beatsPerMeasure;
      });
    });
  }

  @override
  void dispose() {
    _sequenceScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToCurrentSequence() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sequenceScrollController.hasClients || customSequence.isEmpty)
        return;

      const double itemWidth = 130.0;
      final double screenWidth = MediaQuery.of(context).size.width;

      double targetOffset =
          (currentSequenceIndex * itemWidth) + 20.0 - (screenWidth / 2) + 60.0;

      if (targetOffset < 0) targetOffset = 0;
      if (targetOffset > _sequenceScrollController.position.maxScrollExtent) {
        targetOffset = _sequenceScrollController.position.maxScrollExtent;
      }

      if (_sequenceScrollController.position.maxScrollExtent > 0) {
        _sequenceScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadAudioAssets() async {
    try {
      final byteDataTick = await rootBundle.load('assets/tick.wav');
      print(
        'ÉXITO: tick.wav cargado. Tamaño: ${byteDataTick.lengthInBytes} bytes',
      );
      await _engine.loadSampleFromAsset(0, 'assets/tick.wav');

      final byteDataTock = await rootBundle.load('assets/tock.wav');
      print(
        'ÉXITO: tock.wav cargado. Tamaño: ${byteDataTock.lengthInBytes} bytes',
      );
      await _engine.loadSampleFromAsset(1, 'assets/tock.wav');
    } catch (e) {
      print('ERROR: No se pudieron encontrar los archivos WAV. Detalles: $e');
    }
  }

  Future<void> _changeSoundSet(String soundType) async {
    String tickPath = 'assets/tick.wav';
    String tockPath = 'assets/tock.wav';

    switch (soundType) {
      case 'Cowbell':
        tickPath = 'assets/tick_cowbell.wav';
        tockPath = 'assets/tock_cowbell.wav';
        break;
      case 'Whistle':
        tickPath = 'assets/tick_whistle.wav';
        tockPath = 'assets/tock_whistle.wav';
        break;
      case 'Block':
        tickPath = 'assets/tick_block.wav';
        tockPath = 'assets/tock_block.wav';
        break;
      case 'Bit':
        tickPath = 'assets/tick_bit.wav';
        tockPath = 'assets/tock_bit.wav';
        break;
      case 'Can':
        tickPath = 'assets/tick_can.wav';
        tockPath = 'assets/tock_can.wav';
        break;
      case 'Clap':
        tickPath = 'assets/tick_clap.wav';
        tockPath = 'assets/tock_clap.wav';
        break;
      case 'PracticePad':
        tickPath = 'assets/tick_pad.wav';
        tockPath = 'assets/tock_pad.wav';
        break;
      case 'Default':
      default:
        tickPath = 'assets/tick.wav';
        tockPath = 'assets/tock.wav';
        break;
    }

    try {
      await _engine.loadSampleFromAsset(0, tickPath);
      await _engine.loadSampleFromAsset(1, tockPath);
    } catch (e) {
      print(
        'ERROR: No wav file found for $soundType. $e',
      );
    }
  }

  void _updateBpm(String value) {
    int? newBpm = int.tryParse(value);
    if (newBpm != null) {
      if (newBpm < 40) newBpm = 40;
      if (newBpm > 300) newBpm = 300;

      setState(() {
        bpm = newBpm!;
        _engine.setBpm(bpm.toDouble());
      });
    }
  }

  void _showBpmDialog() {
    TextEditingController bpmController = TextEditingController(
      text: bpm.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('BPM', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: bpmController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: currentTheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            autofocus: true,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: currentTheme.primary),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: currentTheme.primary, width: 2),
              ),
            ),
            onSubmitted: (value) {
              _updateBpm(value);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _updateBpm(bpmController.text);
                Navigator.pop(context);
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: currentTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          children: [_buildMetronomePage(), _buildLibraryPage()],
        ),
      ),
    );
  }

  Widget _buildMetronomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedVisualizer,
                  dropdownColor: const Color(0xFF1E1E1E),
                  focusColor: Colors.transparent,
                  style: TextStyle(fontSize: 18, color: currentTheme.primary),
                  underline: const SizedBox(),
                  items:
                      [
                        'Matrix',
                        'Pulse',
                        'Border',
                        'Rings',
                        'Bars',
                        'Oscilloscope',
                        'Pong',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedVisualizer = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(width: 20),
                const Icon(Icons.volume_up, color: Colors.grey, size: 20),
                const SizedBox(width: 5),
                DropdownButton<String>(
                  value: selectedSound,
                  dropdownColor: const Color(0xFF1E1E1E),
                  focusColor: Colors.transparent,
                  style: TextStyle(fontSize: 18, color: currentTheme.primary),
                  underline: const SizedBox(),
                  items: _availableSounds
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != selectedSound) {
                      setState(() {
                        selectedSound = newValue;
                      });
                      _changeSoundSet(newValue);
                    }
                  },
                ),
              ],
            ),
            // --- COLOR SELECTOR ---
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _availableThemes.map((theme) {
                bool isSelected = (currentTheme == theme);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentTheme = theme;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: isSelected ? 30 : 22,
                    height: isSelected ? 30 : 22,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.primary.withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // --- DYNAMIC RENDER ---
            SizedBox(
              height: 150,
              child: Center(
                child: Builder(
                  builder: (context) {
                    switch (selectedVisualizer) {
                      case 'Pulse':
                        return PulseVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          theme: currentTheme,
                        );
                      case 'Border':
                        return BorderGlowVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          theme: currentTheme,
                        );
                      case 'Rings':
                        return RadialRingsVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          theme: currentTheme,
                        );
                      case 'Bars':
                        return RhythmicBarsVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          theme: currentTheme,
                        );
                      case 'Oscilloscope':
                        return TrueOscilloscopeVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          theme: currentTheme,
                        );
                      case 'Pong':
                        return PongVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          bpm: bpm,
                          noteValue: visualNoteValue,
                          theme: currentTheme,
                        );
                      case 'Matrix':
                      default:
                        return MatrixVisualizer(
                          currentBeat: currentVisualBeat,
                          beatsPerMeasure: visualBeatsPerMeasure,
                          theme: currentTheme,
                        );
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 50,
                  color: currentTheme.primary,
                  onPressed: () {
                    setState(() {
                      if (bpm > 40) {
                        bpm--;
                        _engine.setBpm(bpm.toDouble());
                      }
                    });
                  },
                ),

                const SizedBox(width: 20),

                GestureDetector(
                  onTap: _showBpmDialog,
                  child: SizedBox(
                    width: 180,
                    child: Text(
                      '$bpm',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 50,
                  color: currentTheme.primary,
                  onPressed: () {
                    setState(() {
                      if (bpm < 300) {
                        bpm++;
                        _engine.setBpm(bpm.toDouble());
                      }
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Time signature: ',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                DropdownButton<int>(
                  value: beatsPerMeasure,
                  dropdownColor: const Color(0xFF1E1E1E),
                  focusColor: Colors.transparent,
                  style: TextStyle(
                    fontSize: 24,
                    color: currentTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(height: 2, color: currentTheme.primary),
                  items: List.generate(16, (index) => index + 1).map((
                    int value,
                  ) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        beatsPerMeasure = newValue;
                        _engine.setTimeSignature(beatsPerMeasure, noteValue);
                      });
                    }
                  },
                ),

                const Text(
                  ' / ',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),

                DropdownButton<int>(
                  value: noteValue,
                  dropdownColor: const Color(0xFF1E1E1E),
                  focusColor: Colors.transparent,
                  style: TextStyle(
                    fontSize: 24,
                    color: currentTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(height: 2, color: currentTheme.primary),
                  items: [2, 4, 8, 16].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        noteValue = newValue;
                        _engine.setTimeSignature(beatsPerMeasure, noteValue);
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.waves, color: Colors.white),
              label: const Text(
                'Add to score',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.secondary,
              ),
              onPressed: () {
                setState(() {
                  customSequence.add(MeasureBlock(beatsPerMeasure, noteValue));
                  _applySequence();
                });
              },
            ),

            const SizedBox(height: 15),

            if (customSequence.isNotEmpty) ...[
              const Text(
                'Polirythmic sequence: ',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  controller: _sequenceScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: customSequence.length,
                  itemBuilder: (context, index) {
                    final block = customSequence[index];

                    bool isActive =
                        (index == currentSequenceIndex) ||
                        (!isPlaying && currentSequenceIndex == -1);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 120, // <--- Aumentamos un poco el ancho a 120
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? currentTheme.primary
                            : Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isActive
                              ? currentTheme.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: currentTheme.primary.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${block.numerator}/${block.denominator}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),

                          if (isActive || !isPlaying) ...[
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  customSequence.removeAt(index);
                                  _applySequence();
                                });
                              },
                              child: Icon(
                                Icons.close,
                                color: isActive
                                    ? Colors.white70
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.primary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
                elevation: 10,
                shadowColor: currentTheme.primary.withOpacity(0.5),
              ),
              onPressed: () {
                setState(() {
                  isPlaying = !isPlaying;
                  if (isPlaying) {
                    currentSequenceIndex = -1;
                    _engine.play();
                  } else {
                    _engine.stop();
                  }
                });
              },
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repertoire',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_box, size: 30),
                color: currentTheme.primary,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Swipe left to return to the metronome',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 3, // 3 canciones de prueba
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    title: Text(
                      'Canción de Prueba ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '120 BPM • [4/4] [7/8] [5/16]',
                        style: TextStyle(
                          color: currentTheme.secondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_arrow_rounded,
                      color: currentTheme.primary,
                      size: 32,
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MeasureBlock {
  final int numerator;
  final int denominator;

  MeasureBlock(this.numerator, this.denominator);
}

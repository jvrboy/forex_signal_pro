import 'dart:math' as math;
import 'dart:typed_data';

double _nextGaussian(math.Random rng) {
  double u1 = 0, u2 = 0;
  while (u1 <= 0 || u1 >= 1) u1 = rng.nextDouble();
  while (u2 <= 0 || u2 >= 1) u2 = rng.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

class Layer {
  final Float64List weights;
  final Float64List biases;
  final int inputSize;
  final int outputSize;
  final Activation activation;

  Layer({
    required this.inputSize,
    required this.outputSize,
    required this.activation,
    math.Random? random,
  }) : weights = Float64List(inputSize * outputSize),
       biases = Float64List(outputSize) {
    final rng = random ?? math.Random();
    final scale = math.sqrt(2.0 / inputSize);
    for (int i = 0; i < weights.length; i++) {
      weights[i] = _nextGaussian(rng) * scale;
    }
    for (int i = 0; i < biases.length; i++) {
      biases[i] = 0.01;
    }
  }

  Layer.fromWeights({
    required this.weights,
    required this.biases,
    required this.inputSize,
    required this.outputSize,
    required this.activation,
  });

  Float64List forward(Float64List input) {
    assert(input.length == inputSize);
    final output = Float64List(outputSize);
    for (int o = 0; o < outputSize; o++) {
      double sum = biases[o];
      for (int i = 0; i < inputSize; i++) {
        sum += weights[o * inputSize + i] * input[i];
      }
      output[o] = activation.apply(sum);
    }
    return output;
  }

  Float64List forwardWithCache(Float64List input, {Map<String, dynamic>? cache}) {
    final output = forward(input);
    if (cache != null) {
      cache['last_input'] = input;
      cache['last_output'] = output;
    }
    return output;
  }
}

enum Activation { relu, sigmoid, tanh, linear }

extension ActivationX on Activation {
  double apply(double x) {
    switch (this) {
      case Activation.relu:
        return x > 0 ? x : 0;
      case Activation.sigmoid:
        if (x < -10) return 0;
        if (x > 10) return 1;
        return 1 / (1 + math.exp(-x));
      case Activation.tanh:
        return math.tanh(x);
      case Activation.linear:
        return x;
    }
  }

  double derivative(double x) {
    switch (this) {
      case Activation.relu:
        return x > 0 ? 1 : 0;
      case Activation.sigmoid:
        final s = apply(x);
        return s * (1 - s);
      case Activation.tanh:
        final t = apply(x);
        return 1 - t * t;
      case Activation.linear:
        return 1;
    }
  }
}

class SignalScoringNN {
  final List<Layer> layers;
  final double learningRate;
  final math.Random _rng;

  SignalScoringNN({
    required this.layers,
    this.learningRate = 0.001,
  }) : _rng = math.Random();

  factory SignalScoringNN.defaultConfig() {
    return SignalScoringNN(
      layers: [
        Layer(inputSize: 20, outputSize: 64, activation: Activation.relu),
        Layer(inputSize: 64, outputSize: 32, activation: Activation.relu),
        Layer(inputSize: 32, outputSize: 16, activation: Activation.relu),
        Layer(inputSize: 16, outputSize: 1, activation: Activation.sigmoid),
      ],
    );
  }

  double predict(Float64List features) {
    assert(features.length == 20, 'Must have exactly 20 features');
    Float64List current = features;
    for (final layer in layers) {
      current = layer.forward(current);
    }
    return current[0];
  }

  double train(List<TrainingExample> examples, {int epochs = 10}) {
    double totalLoss = 0;
    for (int epoch = 0; epoch < epochs; epoch++) {
      for (final example in examples) {
        totalLoss += _trainStep(example.features, example.label);
      }
    }
    return totalLoss / (examples.length * epochs);
  }

  double _trainStep(Float64List features, double label) {
    final caches = <Map<String, dynamic>>[];
    Float64List current = features;

    for (final layer in layers) {
      final cache = <String, dynamic>{};
      current = layer.forwardWithCache(current, cache: cache);
      caches.add(cache);
    }

    final prediction = current[0];
    final error = prediction - label;
    final loss = error * error;

    final lastOutput = caches.last['last_output'] as Float64List;
    final deltas = Float64List(layers.last.outputSize);
    for (int o = 0; o < layers.last.outputSize; o++) {
      deltas[o] = (o == 0 ? error : 0.0) * layers.last.activation.derivative(lastOutput[o]);
    }

    for (int l = layers.length - 1; l >= 0; l--) {
      final layer = layers[l];
      final input = l == 0 ? features : caches[l - 1]['last_output'] as Float64List;

      for (int o = 0; o < layer.outputSize; o++) {
        layer.biases[o] -= learningRate * deltas[o];

        for (int i = 0; i < layer.inputSize; i++) {
          layer.weights[o * layer.inputSize + i] -= learningRate * deltas[o] * input[i];
        }
      }

      if (l > 0) {
        final prevLayer = layers[l - 1];
        final prevOutput = caches[l - 1]['last_output'] as Float64List;
        final newDeltas = Float64List(prevLayer.outputSize);
        for (int po = 0; po < prevLayer.outputSize; po++) {
          double sum = 0;
          for (int o = 0; o < layer.outputSize; o++) {
            sum += layer.weights[o * layer.inputSize + po] * deltas[o];
          }
          newDeltas[po] = sum * prevLayer.activation.derivative(prevOutput[po]);
        }
        for (int i = 0; i < newDeltas.length; i++) {
          deltas[i] = newDeltas[i];
        }
      }
    }

    return loss;
  }

  List<double> featureImportance({required Float64List baselineFeatures, int samples = 100}) {
    final baseline = predict(baselineFeatures);
    final importances = List.filled(20, 0.0);

    for (int f = 0; f < 20; f++) {
      double totalDelta = 0;
      for (int s = 0; s < samples; s++) {
        final perturbed = Float64List.fromList(baselineFeatures);
        perturbed[f] = _rng.nextDouble() * 2 - 0.5;
        totalDelta += (predict(perturbed) - baseline).abs();
      }
      importances[f] = totalDelta / samples;
    }

    final sum = importances.fold(0.0, (a, b) => a + b);
    if (sum > 0) {
      return importances.map((v) => v / sum).toList();
    }
    return importances;
  }

  Map<String, dynamic> serialize() {
    return {
      'layers': layers.map((l) => {
        'weights': l.weights.toList(),
        'biases': l.biases.toList(),
        'inputSize': l.inputSize,
        'outputSize': l.outputSize,
        'activation': l.activation.name,
      }).toList(),
    };
  }

  factory SignalScoringNN.deserialize(Map<String, dynamic> data) {
    final layers = (data['layers'] as List).map((l) {
      return Layer.fromWeights(
        weights: Float64List.fromList((l['weights'] as List).cast<num>().map((e) => e.toDouble()).toList()),
        biases: Float64List.fromList((l['biases'] as List).cast<num>().map((e) => e.toDouble()).toList()),
        inputSize: l['inputSize'] as int,
        outputSize: l['outputSize'] as int,
        activation: Activation.values.firstWhere((a) => a.name == l['activation']),
      );
    }).toList();

    return SignalScoringNN(layers: layers);
  }
}

class TrainingExample {
  final Float64List features;
  final double label;

  const TrainingExample({required this.features, required this.label});
}

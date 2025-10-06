import 'dart:math' as math;

class SimilarityResult {
  final double similarity;
  final String projectId;
  final String projectTitle;
  final String projectDescription;
  final String domain;
  final String studentName;
  final String? year;
  final String? semester;

  SimilarityResult({
    required this.similarity,
    required this.projectId,
    required this.projectTitle,
    required this.projectDescription,
    required this.domain,
    required this.studentName,
    this.year,
    this.semester,
  });
}

class DomainSuggestion {
  final String domain;
  final double confidence;
  final List<SimilarityResult> supportingProjects;

  DomainSuggestion({
    required this.domain,
    required this.confidence,
    required this.supportingProjects,
  });
}

class SimilarityCheckResult {
  final List<SimilarityResult> topSimilarProjects;
  final DomainSuggestion suggestedDomain;
  final bool hasHighSimilarity;
  final double maxSimilarity;

  SimilarityCheckResult({
    required this.topSimilarProjects,
    required this.suggestedDomain,
    required this.hasHighSimilarity,
    required this.maxSimilarity,
  });
}

class SimilarityService {
  static const double highSimilarityThreshold = 0.7;
  static const int maxSimilarProjects = 3;

  /// Calculate TF-IDF similarity between a new project and existing projects
  static SimilarityCheckResult calculateSimilarity({
    required String title,
    required String description,
    required List<Map<String, dynamic>> existingProjects,
  }) {
    if (existingProjects.isEmpty) {
      return SimilarityCheckResult(
        topSimilarProjects: [],
        suggestedDomain: _getSmartDefaultDomain(title, description), // Use smart domain detection
        hasHighSimilarity: false,
        maxSimilarity: 0.0,
      );
    }

    final newProjectText = _preprocessText('$title $description');
    final newProjectWords = _tokenize(newProjectText);
    
    // Calculate similarity with each existing project
    List<SimilarityResult> similarities = [];
    
    for (var project in existingProjects) {
      final projectTitle = project['topic']?.toString() ?? '';
      final projectDesc = project['description']?.toString() ?? '';
      final projectText = _preprocessText('$projectTitle $projectDesc');
      final projectWords = _tokenize(projectText);
      
      final similarity = _calculateCosineSimilarity(newProjectWords, projectWords);
      
      similarities.add(SimilarityResult(
        similarity: similarity,
        projectId: project['id']?.toString() ?? '',
        projectTitle: projectTitle,
        projectDescription: projectDesc,
        domain: project['domain']?.toString() ?? 'Unknown',
        studentName: project['studentName']?.toString() ?? 'Unknown',
        year: project['year']?.toString(),
        semester: project['semester']?.toString(),
      ));
    }
    
    // Sort by similarity (highest first) and take top results
    similarities.sort((a, b) => b.similarity.compareTo(a.similarity));
    final topSimilarities = similarities.take(maxSimilarProjects).toList();
    
    // Calculate domain suggestion with fallback to smart analysis
    final domainSuggestion = _calculateDomainSuggestion(similarities, title, description);
    
    final maxSimilarity = similarities.isNotEmpty ? similarities.first.similarity : 0.0;
    final hasHighSimilarity = maxSimilarity > highSimilarityThreshold;
    
    return SimilarityCheckResult(
      topSimilarProjects: topSimilarities,
      suggestedDomain: domainSuggestion,
      hasHighSimilarity: hasHighSimilarity,
      maxSimilarity: maxSimilarity,
    );
  }

  /// Preprocess text by converting to lowercase and removing special characters
  static String _preprocessText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Tokenize text into words and remove common stop words
  static List<String> _tokenize(String text) {
    const stopWords = {
      'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
      'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
      'to', 'was', 'were', 'will', 'with', 'this', 'we', 'you', 'they',
      'them', 'their', 'there', 'these', 'those', 'some', 'any', 'all',
      'can', 'could', 'would', 'should', 'may', 'might', 'must', 'shall',
      'his', 'her', 'our', 'your', 'my', 'me', 'i', 'am', 'do', 'does',
      'did', 'have', 'had', 'having', 'been', 'being', 'go', 'went',
      'gone', 'going', 'get', 'got', 'getting', 'make', 'made', 'making'
    };

    return text
        .split(' ')
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();
  }

  /// Calculate cosine similarity between two lists of words
  static double _calculateCosineSimilarity(List<String> words1, List<String> words2) {
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    // Create term frequency maps
    final tf1 = _calculateTermFrequency(words1);
    final tf2 = _calculateTermFrequency(words2);

    // Get all unique terms
    final allTerms = {...tf1.keys, ...tf2.keys};

    // Calculate vectors
    final vector1 = allTerms.map((term) => tf1[term] ?? 0.0).toList();
    final vector2 = allTerms.map((term) => tf2[term] ?? 0.0).toList();

    // Calculate dot product
    double dotProduct = 0.0;
    for (int i = 0; i < vector1.length; i++) {
      dotProduct += vector1[i] * vector2[i];
    }

    // Calculate magnitudes
    final magnitude1 = math.sqrt(vector1.map((v) => v * v).reduce((a, b) => a + b));
    final magnitude2 = math.sqrt(vector2.map((v) => v * v).reduce((a, b) => a + b));

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// Calculate term frequency for a list of words
  static Map<String, double> _calculateTermFrequency(List<String> words) {
    final frequency = <String, int>{};
    
    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    final totalWords = words.length;
    return frequency.map((term, count) => MapEntry(term, count / totalWords));
  }

  /// Calculate domain suggestion based on similarity scores
  static DomainSuggestion _calculateDomainSuggestion(List<SimilarityResult> similarities, String title, String description) {
    if (similarities.isEmpty) {
      // Provide intelligent fallback based on common project types
      return _getSmartDefaultDomain(title, description);
    }

    // Group similarities by domain and calculate weighted scores
    final domainScores = <String, double>{};
    final domainProjects = <String, List<SimilarityResult>>{};

    for (final result in similarities) {
      final domain = result.domain;
      // Give more weight to higher similarity scores
      final weightedScore = result.similarity * result.similarity; // Square for emphasis
      domainScores[domain] = (domainScores[domain] ?? 0.0) + weightedScore;
      domainProjects[domain] = (domainProjects[domain] ?? [])..add(result);
    }

    // Find the domain with highest weighted score
    String bestDomain = 'Web Development';
    double bestScore = 0.0;
    
    domainScores.forEach((domain, score) {
      if (score > bestScore) {
        bestScore = score;
        bestDomain = domain;
      }
    });

    // If no significant similarity found, use intelligent fallback
    if (bestScore < 0.1 || domainProjects[bestDomain]!.isEmpty) {
      return _getSmartDefaultDomain(title, description);
    }

    // Calculate confidence based on the top similarity score and number of supporting projects
    final supportingProjects = domainProjects[bestDomain] ?? [];
    final confidence = supportingProjects.isNotEmpty 
        ? supportingProjects.first.similarity 
        : 0.0;

    return DomainSuggestion(
      domain: bestDomain,
      confidence: confidence,
      supportingProjects: supportingProjects.take(3).toList(),
    );
  }

  /// Provide smart domain suggestion based on project content analysis
  static DomainSuggestion _getSmartDefaultDomain(String title, String description) {
    final combinedText = '$title $description'.toLowerCase();
    
    // Define domain keywords
    final domainKeywords = {
      'AI/ML': ['ai', 'artificial intelligence', 'machine learning', 'neural', 'deep learning', 'classification', 'prediction', 'model', 'algorithm', 'tensorflow', 'python', 'data mining', 'nlp', 'computer vision'],
      'Mobile Development': ['android', 'ios', 'mobile', 'app', 'flutter', 'react native', 'kotlin', 'swift', 'firebase', 'smartphone'],
      'Web Development': ['web', 'website', 'html', 'css', 'javascript', 'react', 'vue', 'angular', 'node', 'backend', 'frontend', 'api', 'rest', 'http'],
      'IoT': ['iot', 'internet of things', 'sensor', 'arduino', 'raspberry pi', 'embedded', 'automation', 'smart home', 'wireless', 'bluetooth'],
      'Data Science': ['data science', 'analytics', 'visualization', 'statistics', 'big data', 'dashboard', 'reporting', 'insights', 'pandas', 'matplotlib'],
      'Blockchain': ['blockchain', 'cryptocurrency', 'bitcoin', 'ethereum', 'smart contract', 'decentralized', 'crypto', 'ledger'],
      'Cybersecurity': ['security', 'cybersecurity', 'encryption', 'firewall', 'penetration', 'vulnerability', 'cyber', 'hacking'],
      'Game Development': ['game', 'gaming', 'unity', 'unreal', '2d', '3d', 'graphics', 'animation'],
    };
    
    // Score each domain based on keyword matches
    final domainScores = <String, int>{};
    
    domainKeywords.forEach((domain, keywords) {
      int score = 0;
      for (final keyword in keywords) {
        if (combinedText.contains(keyword)) {
          score += keyword.length > 5 ? 3 : 1; // Give more points for specific keywords
        }
      }
      domainScores[domain] = score;
    });
    
    // Find the highest scoring domain
    String bestDomain = 'Web Development'; // Default fallback
    int bestScore = 0;
    
    domainScores.forEach((domain, score) {
      if (score > bestScore) {
        bestScore = score;
        bestDomain = domain;
      }
    });
    
    return DomainSuggestion(
      domain: bestDomain,
      confidence: bestScore > 0 ? 0.5 : 0.0, // Medium confidence for keyword-based suggestions
      supportingProjects: [],
    );
  }

  /// Get formatted similarity percentage string
  static String getFormattedSimilarity(double similarity) {
    return '${(similarity * 100).toStringAsFixed(1)}%';
  }

  /// Check if similarity is considered high
  static bool isHighSimilarity(double similarity) {
    return similarity > highSimilarityThreshold;
  }

  /// Get color for similarity level
  static String getSimilarityLevel(double similarity) {
    if (similarity > highSimilarityThreshold) {
      return 'High';
    } else if (similarity > 0.4) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
}
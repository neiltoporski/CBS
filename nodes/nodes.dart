/// Representation of a single Decision Making Node choice.
class Choice {
  String option;
  int score;
  String explanation;

  Choice(this.option, this.score, this.explanation);

  /// Option field of Choice. This is a potential choice for a User to select.
  String get getOption {
    return option;
  }

  set setOption(String newOption) {
    option = newOption;
  }

  /// Score field of Choice. This is the score that will be applied to the User if the choice is selected.
  int get getScore {
    return score;
  }

  set setScore(int newScore) {
    score = newScore;
  }

  /// Explanation field of Choice. This is the explanation given to the User about the correctness of the Choice displayed at the End Node.
  String get getExplanation {
    return explanation;
  }

  void setExplanation(String newExplanation) {
    explanation = newExplanation;
  }
}

/// Representation of a single Information Gathering Node choice.
class IGChoice extends Choice {
  String information;

  IGChoice(super.option, super.score, super.explanation, this.information);

  /// Information field of IGChoice. This is the information the User will gather at the Node if selected.
  String get getInformation {
    return information;
  }

  set setInformation(String newInformation) {
    information = newInformation;
  }
}

/// Representation of a Node in a Simulation.
class NodeSim {
  String? audioUrl;
  String? imageUrl;
  String? videoUrl;
  String? storyText;
  bool isVisible;
  String? parent;
  late List<String>? children;

  NodeSim(this.audioUrl, this.imageUrl, this.videoUrl, this.storyText,
      this.isVisible, this.parent);

  String? get getImageUrl {
    return imageUrl;
  }

  set setImageUrl(String newImageUrl) {
    imageUrl = newImageUrl;
  }

  String? get getAudioUrl {
    return audioUrl;
  }

  set setAudioUrl(String newAudioUrl) {
    audioUrl = newAudioUrl;
  }

  String? get getVideoUrl {
    return videoUrl;
  }

  set setVideoUrl(String newVideoUrl) {
    videoUrl = newVideoUrl;
  }

  /// StoryText field of Node. This is the text description the Node will display to Users.
  String? get getStoryText {
    return storyText;
  }

  set setStoryText(String newText) {
    storyText = newText;
  }

  /// IsVisible field of Node. This determine's the Node's visibility in the Tree view for Users.
  bool get getIsVisible {
    return isVisible;
  }

  set setIsVisible(bool newVal) {
    isVisible = newVal;
  }

  /// Parent field of Node. This is the parent of the Node in the Tree view.
  String? get getParent {
    return parent;
  }

  //void set setParent(Node newParent){
  set setParent(String? newParent) {
    parent = newParent;
  }

  /// Children field of Node. These are the children of the Node in the Tree view.
  List<String>? get getChildren {
    return children;
  }

  int? get getChildrenSize {
    if (children == null) {
      return 0;
    } else {
      return children?.length;
    }
  }

  String? getChild(int index) {
    return children?[index];
  }

  //void set setChildren(List<Node> newChildren){
  set setChildren(List<String>? newChildren) {
    children = newChildren;
  }
}

class ScenarioNode extends NodeSim {
  ScenarioNode(super.audioUrl, super.imageUrl, super.videoUrl, super.storyText,
      super.isVisible, super.parent);
}

class EndNode extends NodeSim {
  EndNode(super.audioUrl, super.imageUrl, super.videoUrl, super.storyText,
      super.isVisible, super.parent);
}

class ScoreNode extends NodeSim {
  ScoreNode(super.audioUrl, super.imageUrl, super.videoUrl, super.storyText,
      super.isVisible, super.parent);
}

class IGNode extends ScoreNode {
  List<IGChoice> choices;

  IGNode(super.audioUrl, super.imageUrl, super.videoUrl, super.storyText,
      super.isVisible, super.parent, this.choices);

  List<IGChoice> get getChoices {
    return choices;
  }

  set setChoices(List<IGChoice> newChoices) {
    choices = newChoices;
  }
}

class DMNode extends ScoreNode {
  List<Choice> choices;

  DMNode(super.audioUrl, super.imageUrl, super.videoUrl, super.storyText,
      super.isVisible, super.parent, this.choices);

  List<Choice> get getChoices {
    return choices;
  }

  set setChoices(List<Choice> newChoices) {
    choices = newChoices;
  }
}

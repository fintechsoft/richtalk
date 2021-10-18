class EmailChannelConfiguration {
  String from;
  String fromName;
  String templateId;
  String usernameSubstitution;

  EmailChannelConfiguration(
      {this.from, this.fromName, this.templateId, this.usernameSubstitution});

  Map<String, dynamic> toMap() {
    return {
      'from': this.from,
      'from_name': this.fromName,
      'template_id': this.templateId,
      'substitutions': {
        if (this.usernameSubstitution != null)
          "username": this.usernameSubstitution
      }
    };
  }
}

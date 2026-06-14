const List<Map<String, String>> kStarterPrompts = [
  {
    'title': 'Rewrite professionally',
    'body': 'Rewrite the following text in a clear, professional tone:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Summarize concisely',
    'body': 'Summarize the following in 3 bullet points:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': "Explain like I'm 5",
    'body': 'Explain the following concept as if explaining to a 5-year-old:\n\n{{concept}}',
    'modelTags': '',
  },
  {
    'title': 'Fix grammar and spelling',
    'body': 'Fix any grammar, spelling, and punctuation errors in the following text. Return only the corrected text:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Make it shorter',
    'body': 'Rewrite the following to be 50% shorter while keeping the key points:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Translate to {{language}}',
    'body': 'Translate the following text to {{language}}:\n\n{{text}}',
    'modelTags': '',
  },
  {
    'title': 'Write an email',
    'body': 'Write a professional email about: {{topic}}\n\nTone: {{tone}}\nRecipient: {{recipient}}',
    'modelTags': '',
  },
  {
    'title': 'Code review',
    'body': 'Review the following code for bugs, edge cases, and improvements:\n\n```\n{{code}}\n```\n\nLanguage: {{language}}',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Explain this code',
    'body': 'Explain what this code does step by step:\n\n```\n{{code}}\n```',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Write unit tests',
    'body': 'Write comprehensive unit tests for the following code. Cover happy path, edge cases, and error paths:\n\n```{{language}}\n{{code}}\n```',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Debug this error',
    'body': 'I\'m getting this error:\n\n{{error}}\n\nHere is the relevant code:\n\n```\n{{code}}\n```\n\nWhat is causing it and how do I fix it?',
    'modelTags': 'claude,chatgpt',
  },
  {
    'title': 'Midjourney portrait',
    'body': 'portrait of {{subject}}, {{style}} style, dramatic lighting, highly detailed, 8k, cinematic, professional photography --ar 2:3 --q 2',
    'modelTags': 'image',
  },
  {
    'title': 'Midjourney landscape',
    'body': '{{scene}}, golden hour, {{mood}} atmosphere, hyperrealistic, landscape photography, award winning, 8k --ar 16:9 --q 2',
    'modelTags': 'image',
  },
  {
    'title': 'Brainstorm ideas',
    'body': 'Generate 10 creative ideas for: {{topic}}\n\nConstraints: {{constraints}}\nTarget audience: {{audience}}',
    'modelTags': '',
  },
  {
    'title': 'Claude XML structured prompt',
    'body': '<role>\n{{role}}\n</role>\n\n<task>\n{{task}}\n</task>\n\n<format>\n{{format}}\n</format>',
    'modelTags': 'claude',
  },
  {
    'title': 'Study flashcards',
    'body': 'Create 5 flashcard-style Q&A pairs to help me study:\n\n{{topic}}',
    'modelTags': '',
  },
  {
    'title': 'Pros and cons',
    'body': 'List the pros and cons of:\n\n{{decision}}\n\nContext: {{context}}',
    'modelTags': '',
  },
  {
    'title': 'Improve this prompt',
    'body': 'Improve the following AI prompt to be more effective, specific, and likely to produce better results:\n\n{{prompt}}',
    'modelTags': '',
  },
  {
    'title': 'Write a LinkedIn post',
    'body': 'Write a LinkedIn post about: {{topic}}\n\nTone: professional but approachable\nLength: 150-200 words\nInclude: a hook, insight, and call to action',
    'modelTags': '',
  },
  {
    'title': 'Meeting agenda',
    'body': 'Create a structured meeting agenda for:\n\nMeeting purpose: {{purpose}}\nDuration: {{duration}}\nAttendees: {{attendees}}',
    'modelTags': '',
  },
];

Pod::Spec.new do |spec|
  spec.name = "PWMRLive"
  spec.version = "1.1.5"
  spec.summary = "Simplify ScreenRecorder Live"
  spec.homepage = "https://github.com/fanlilinSaber/MRLive"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Fan Li Lin" => 'fanlilin@i-focusing.com' }
  spec.platform = :ios, "8.4"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/fanlilinSaber/MRLive.git", tag: spec.version, submodules: true }
  spec.source_files = "Sources/**/*.{h,m}"
  spec.resources = "Sources/*.bundle"
  spec.dependency "TXLiteAVSDK_Professional", '~> 6.3.0'
end

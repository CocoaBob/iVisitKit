Pod::Spec.new do |s|
  s.name              = "iVisitKit"
  s.version           = "0.0.1"
  s.summary           = "A kit to play PNO files for iVisit 360 (iVisit 3D)."
  s.homepage          = "https://github.com/CocoaBob/iVisitKit"
  s.author            = { "CocoaBob" => "mengke.wang@gmail.com" }
  s.social_media_url  = "http://twitter.com/CocoaBob"
  s.source            = { :git => "https://github.com/CocoaBob/iVisitKit.git", :tag => "v#{s.version}" }
  s.platform          = :ios, '11.0'
  s.source_files      = "iVisitKit/**/*.{h,m,c}"
  s.resources         = "iVisitKit/**/*.{png,xib,storyboard}"
  s.resource_bundle = { "Images" => ["iVisitKit/Images.xcassets"] }
  s.requires_arc      = true
end
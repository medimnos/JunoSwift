Pod::Spec.new do |s|
    s.name             = 'JunoSwift'
    s.version          = '1.1.6'
    s.summary          = 'JunoSwift is a collection of fluent libraries for consuming SharePoint, Graph, and Office 365 REST APIs in a type-safe way.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = 'JunoSwift is a collection of fluent libraries for consuming SharePoint, Graph, and Office 365 REST APIs in a type-safe way.'
    
    s.homepage         = 'https://github.com/medimnos/JunoSwift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Uğur Uğurlu' => 'ugurugurlu@ogoodigital.com' }
    s.source           = { :git => 'https://github.com/medimnos/JunoSwift', :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/medimnos'
    
    s.ios.deployment_target = '12.0'
    s.swift_version = '5.0'
    
    s.source_files  = "JunoSwift/**/*.{h,m,swift}"
    s.dependency   'Alamofire'
    s.dependency   'MSAL'
end
# Include hook code here
ActiveRecord::Base.send :include, ActsAsAddress
String.send :include, ActsAsAddress::StringMethods
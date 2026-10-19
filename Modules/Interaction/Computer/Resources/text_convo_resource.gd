extends Resource
class_name TextConvo


@export var person0 : String
@export var person1 : String
@export_multiline var conversation : String
# Format:
# 
# [time],[person][message]
# 0,0Hi John
# 10,1Hi Billy
# 15,0How is work?
#

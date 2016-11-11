# class Attachment
#   attr_accessor :path, :page_name

#   def initialize(file_path, name)
#     @path = file_path
#     @page_name = name
#   end

#   def name
#     File.basename(@path)
#   end

#   # TODO: check if the singular "_attachment "is correct
#   def link_path
#     File.join('/_attachment', @page_name, name)
#   end

#   def delete_path
#     File.join('/a/file/delete', @page_name, name)
#   end

#   def image?
#     ext = File.extname(@path)
#     case ext
#     when '.png', '.jpg', '.jpeg', '.gif'; return true
#     else; return false
#     end
#   end

#   def size
#     size = File.size(@path).to_i
#     case
#     when size.to_i == 1;     "1 Byte"
#     when size < 1024;        "%d Bytes" % size
#     when size < (1024*1024); "%.2f KB"  % (size / 1024.0)
#     else                     "%.2f MB"  % (size / (1024 * 1024.0))
#     end.sub(/([0-9])\.?0+ /, '\1 ' )
#   end
# end

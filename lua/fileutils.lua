local fileutils={}
  

--- Read a file referenced by fileref into a string.
-- @param fileref [string or a fileref from sasxx.new()] - The fileref to read from
-- @return contents [string] - The contents of the fileref, nil if nothing was found
-- @return msg [string] - Any error message
function fileutils.read( fileref )
   if type(fileref) == "string" then
       fileref =  sasxx.new(fileref)
   end
   local path = fileref:info().path   
   if not path then
      fileref:deassign()
      return nil, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for read."   
   end

   local BUFSIZE = 2^18
   local f = io.open(path,"rb")
   if not f then
      return nil, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for read."   
   end   

   local contents = ""
   while true do
      local bufread = f:read(BUFSIZE)
      if not bufread then break end
      contents = contents..bufread
   end
   f:close()
   return contents,""
end


--- Write a file referenced by fileref from a string with carriage returns
-- @param fileref [string or a fileref from sasxx.new()] - The fileref to write to
-- @param txt  - the string being written to the file
-- @return rc [boolean] true if no error, false otherwise
function fileutils.write( fileref, txt )
    if type(fileref) == "string" then
       fileref =  sasxx.new(fileref)
   end   
   local path = fileref:info().path   
   if not path then
      fileref:deassign()
      return false, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for write."   
   end  
    
   local f = io.open(path,"wb")
   if not f then       
      return false, "ERROR: Couldn't open file: "..path.." for write."
   end
   f:write(txt)
   f:close()
   return true
end

--- Get last modified date of a file referenced by fileref into a string.
-- @param fileref [string or a fileref from sasxx.new()] - The fileref to read from
-- @return lastmodified [string] - The last modified date of the fileref, nil if nothing was found
function fileutils.lastmodified(fileref)
  
   if type(fileref) == "string" then
       fileref =  sasxx.new(fileref)
   end
   local path = fileref:info().path   
   if not path then
      fileref:deassign()
      return nil, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for read."   
   end

   local lastmodified = ""
   
   logical = sasxx.assign(path)
   d = logical:info().lastmod

   local months = {jan='01', feb='02', mar='03', apr='04', may='05', jun='06', jul='07', aug='08', sep='09', oct='10', nov='11', dec='12'} 

   local day, month, year, time = d:match('^(%d%d)(%D%D%D)(%d%d%d%d):(.*)$')
   local lastmodified = year.."-"..months[month].."-"..day
      
   return lastmodified,""  

end


function file_exists(path)
  local f = io.open(path)
  if f == nil then return end
  f:close()
  return path
end

--------------------------------------------------------------------------------
-- Read the whole configuration in a table such that each section is a key to
-- key/value pair table containing the corresponding pairs from the file.
-- Optionally limit to a section

function fileutils.read_config(filename)
  filename = filename or ''
  assert(type(filename) == 'string')
  local ans,u,k,v,temp = {}
  if not file_exists(filename) then return ans end
  for line in io.lines(filename) do
    temp = line:match('^%[(.+)%]$')  -- section
    if temp ~= nil and u ~= temp then u = temp end
    k,v = line:match('^([^#=]+)=(.+)$')
    if u ~= nil then
      ans[u] = ans[u] or {}
      if k ~= nil then
        ans[u][k] = v
      end
    end
  end
  return ans
end


return fileutils
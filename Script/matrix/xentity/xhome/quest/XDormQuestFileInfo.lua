local type = type
local pairs = pairs

--[[public class XQuestFile
{
    // 文件id
    public int FileId;
    // 是否查看
    public bool IsRead;
}]]

local Default = {
    _FileId = 0, -- 文件id
    _IsRead = false, -- 是否查看
}

---@class XDormQuestFileInfo
local XDormQuestFileInfo = XClass(nil, "XDormQuestFileInfo")

function XDormQuestFileInfo:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if data then
        self:UpdateData(data)
    end
end

function XDormQuestFileInfo:UpdateData(data)
    self._FileId = data.FileId
    self._IsRead = data.IsRead
end

-- 获取文件Id
function XDormQuestFileInfo:GetFileId()
    return self._FileId
end

-- 是否查看
function XDormQuestFileInfo:GetIsRead()
    return self._IsRead
end

-- 记录已查阅文件
function XDormQuestFileInfo:RecordReadFile()
    self._IsRead = true
end

return XDormQuestFileInfo
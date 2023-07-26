local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XExFubenCollegeStudyManager = XClass(XExFubenBaseManager, "XExFubenCollegeStudyManager")

function XExFubenCollegeStudyManager:Ctor(chapterType)
    self.ExConfig = XFubenConfigs.GetCollegeChapterBannerByType(chapterType)
end

function XExFubenCollegeStudyManager:ExGetConfig()
    return self.ExConfig
end

function XExFubenCollegeStudyManager:ExSetConfig(config)
end


function XExFubenCollegeStudyManager:ExGetFunctionNameType()
    return self:ExGetConfig().FunctionId
end

function XExFubenCollegeStudyManager:ExGetName()
    return self:ExGetConfig().SimpleDesc
end

function XExFubenCollegeStudyManager:ExGetIcon()
    return self:ExGetConfig().Icon
end

function XExFubenCollegeStudyManager:ExGetTagInfo()
end

return XExFubenCollegeStudyManager
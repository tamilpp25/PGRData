local XPlanetIObject = require("XEntity/XPlanet/XGameObject/XPlanetIObject")

---@class XChapterPlanet:XPlanetIObject
local XChapterPlanet = XClass(XPlanetIObject, "XPlanet")

function XChapterPlanet:Ctor(root, chapterId)
    self.ChapterId = chapterId
end

function XChapterPlanet:GetAssetPath()
    return XPlanetStageConfigs.GetChapterPlanetPrefabUrl(self.ChapterId)
end

function XChapterPlanet:GetObjName()
    return "ChapterPlanet" .. self.ChapterId
end

return XChapterPlanet
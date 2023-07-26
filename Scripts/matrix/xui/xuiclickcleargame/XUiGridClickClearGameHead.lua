local textManager = CS.XTextManager
local tableInsert = table.insert

local XUiGridClickClearGameHead = XClass(nil, "XUiGridClickClearGameHead")

local PathHeadLine = "Head/EffectLine"
local PathHeadLine1 = "Head/EffectLine1"
local PathHeadLine2 = "Head/EffectLine2"

function XUiGridClickClearGameHead:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Head = self.Transform:Find("Head")
    self.CanvasGroup = self.Head.transform:GetComponent("CanvasGroup")
    self.Image = self.Transform:Find("Head/Image")

    self.ImageGO = self.Image.gameObject
    self.ImageRT = self.Image:GetComponent("RectTransform")
    self.ImageSizeDelta = self.ImageRT.sizeDelta

    self.AvatarRT = self.Transform:Find("Head/Avatar"):GetComponent("RectTransform")
    self.AvatarY = self.AvatarRT.localPosition.y
    self.AvatarSizeDelta = self.AvatarRT.sizeDelta

    self.RectTransformDict = {}
    self.OriginYDict = {}
    -- self.SizeDeltaDict = {}
    self:InitY(PathHeadLine)
    self:InitY(PathHeadLine1)
    self:InitY(PathHeadLine2)
end

function XUiGridClickClearGameHead:Init(rootUi)
    self.rootUi = rootUi
end

function XUiGridClickClearGameHead:Refresh(headInfo, realIndex, index)
    local isBeCatched = XDataCenter.XClickClearGameManager.CheckHeadIsCatch(realIndex, index)
    if isBeCatched then
        self.HeadIcon.gameObject:SetActiveEx(false)
        return
    end
    local iconPath = headInfo.Url
    self.RawImageAvatar:SetRawImage(iconPath)
    self.HeadIcon.gameObject:SetActiveEx(true)
end

function XUiGridClickClearGameHead:OnRecycle()
    if self.CanvasGroup.alpha < 1 then
        self.CanvasGroup.alpha = 1
        -- self.ImageGO:SetActiveEx(false)
        self.ImageRT.sizeDelta = CS.UnityEngine.Vector2(self.ImageSizeDelta.x, self.ImageSizeDelta.y)

        self.AvatarRT.localPosition = CS.UnityEngine.Vector3(self.AvatarRT.localPosition.x, self.AvatarY, 0)
        self.AvatarRT.sizeDelta = CS.UnityEngine.Vector2(self.AvatarSizeDelta.x, self.AvatarSizeDelta.y)

        self:ResetY(PathHeadLine)
        self:ResetY(PathHeadLine1)
        self:ResetY(PathHeadLine2)
    end
end

function XUiGridClickClearGameHead:OnClick(index)
    XDataCenter.XClickClearGameManager.OnTouchedHead(index, self)
end

function XUiGridClickClearGameHead:InitY(path)
    local rt = self.Transform:Find(path):GetComponent("RectTransform")
    self.RectTransformDict[path] = rt
    self.OriginYDict[path] = rt.localPosition.y
    -- self.SizeDeltaDict[path] =  rt.sizeDelta
end

function XUiGridClickClearGameHead:ResetY(path)
    local rt = self.RectTransformDict[path]
    rt.localPosition = CS.UnityEngine.Vector3(rt.localPosition.x, self.OriginYDict[path], 0)
    -- rt.sizeDelta = CS.UnityEngine.Vector2(self.AvatarSizeDelta.x, self.AvatarSizeDelta.y)
end

return XUiGridClickClearGameHead
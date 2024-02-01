local DefaultPos = CS.UnityEngine.Vector3(0, 0, 0)
local DefaultScale = CS.UnityEngine.Vector3(1.1, 1.1, 1.1)
local DefaultAspectRatio = 1
local DefaultBgIndex = 1

local AspectRatioFitter
local AspectRatioFitter2
local CanvasGroup
local CanvasGroupBg

local XMovieActionBgSwitch = XClass(XMovieActionBase, "XMovieActionBgSwitch")

function XMovieActionBgSwitch:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Record = {}
    self.BgPath = params[1]
    self.AspectRatioPercent = paramToNumber(params[2])
    self.NeedSupportAnim = self.BeginAnim == "RImgBg2Enable"

    local bgAlpha = params[3]
    self.BgAlpha = bgAlpha and bgAlpha ~= "" and tonumber(bgAlpha) or nil
    local bgIndex = params[4]
    self.BgIndex = bgIndex and paramToNumber(bgIndex) or DefaultBgIndex
    self.IsHide = params[5] == "1"
end

function XMovieActionBgSwitch:OnUiRootInit()
    self.RImgBg = self.UiRoot["RImgBg".. tostring(self.BgIndex)] 
    self.RImgAnimBg = self.BgIndex == DefaultBgIndex and self.UiRoot.RImgBg2 or nil

    if self.RImgBg then
        AspectRatioFitter = self.RImgBg.transform:GetComponent("XAspectRatioFitter")
        CanvasGroup = self.RImgBg.transform:GetComponent("CanvasGroup")
        DefaultAspectRatio = AspectRatioFitter.aspectRatio
    end
    if self.RImgAnimBg then
        AspectRatioFitter2 = self.RImgAnimBg.transform:GetComponent("XAspectRatioFitter")
    end
    CanvasGroupBg = self.UiRoot.Transform:FindTransform("FullScreenBackground"):GetComponent("CanvasGroup")
end

function XMovieActionBgSwitch:OnUiRootDestroy()
    CanvasGroup = nil
    AspectRatioFitter = nil
    AspectRatioFitter2 = nil
    DefaultAspectRatio = 1
end

function XMovieActionBgSwitch:OnInit()
    self.RImgBg.gameObject:SetActiveEx(not self.IsHide)
    if self.IsHide then
        return
    end

    local bgPath = self.BgPath
    local aspectRatioPercent = self.AspectRatioPercent
    local ratio = aspectRatioPercent > 0 and DefaultAspectRatio * aspectRatioPercent or DefaultAspectRatio
    local rImgBg = self.RImgBg
    local loadRawImage = rImgBg.gameObject:GetComponent("XLoadRawImage")
    if loadRawImage then
        self.Record.BgPath = loadRawImage.AssetUrl
    end
    rImgBg.rectTransform.anchoredPosition3D = DefaultPos
    rImgBg.transform.localScale = DefaultScale
    AspectRatioFitter.aspectRatio = ratio
    rImgBg.gameObject:SetActiveEx(true)

    if self.NeedSupportAnim and self.RImgAnimBg then
        rImgBg = self.RImgAnimBg
        rImgBg:SetRawImage(bgPath)
        rImgBg.transform.localScale = DefaultScale
        rImgBg.rectTransform.anchoredPosition3D = DefaultPos
        AspectRatioFitter2.aspectRatio = ratio
        rImgBg.gameObject:SetActiveEx(true)
    else
        rImgBg:SetRawImage(bgPath)
    end

    local bgAlpha = self.BgAlpha
    if bgAlpha then
        CanvasGroupBg.alpha = bgAlpha
    end
end

function XMovieActionBgSwitch:OnExit()
    if self.NeedSupportAnim then
        CanvasGroup.alpha = 1
        if not self.IsHide then
            self.RImgBg:SetRawImage(self.BgPath)
        end
        if self.RImgAnimBg then
            self.RImgAnimBg.gameObject:SetActiveEx(false)
        end
    end
end

function XMovieActionBgSwitch:OnUndo()
    if self.Record.BgPath then
        self.RImgBg:SetRawImage(self.Record.BgPath)
    end
end

return XMovieActionBgSwitch
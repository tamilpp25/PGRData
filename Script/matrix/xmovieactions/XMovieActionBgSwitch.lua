local DefaultPos = CS.UnityEngine.Vector3(0, 0, 0)
local DefaultScale = CS.UnityEngine.Vector3(1.1, 1.1, 1.1)
local DefaultAspectRatio = 1

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

    local param = params[3]
    self.BgAlpha = param and param ~= "" and tonumber(param) or nil
end

function XMovieActionBgSwitch:OnUiRootInit()
    AspectRatioFitter = self.UiRoot.RImgBg1.transform:GetComponent("XAspectRatioFitter")
    AspectRatioFitter2 = self.UiRoot.RImgBg2.transform:GetComponent("XAspectRatioFitter")
    CanvasGroup = self.UiRoot.RImgBg1.transform:GetComponent("CanvasGroup")
    DefaultAspectRatio = AspectRatioFitter.aspectRatio
    CanvasGroupBg = self.UiRoot.Transform:FindTransform("FullScreenBackground"):GetComponent("CanvasGroup")
end

function XMovieActionBgSwitch:OnUiRootDestroy()
    CanvasGroup = nil
    AspectRatioFitter = nil
    AspectRatioFitter2 = nil
    DefaultAspectRatio = 1
end

function XMovieActionBgSwitch:OnInit()
    local bgPath = self.BgPath
    local aspectRatioPercent = self.AspectRatioPercent
    local ratio = aspectRatioPercent > 0 and DefaultAspectRatio * aspectRatioPercent or DefaultAspectRatio
    local rImgBg = self.UiRoot.RImgBg1
    local loadRawImage = rImgBg.gameObject:GetComponent("XLoadRawImage")
    if loadRawImage then
        self.Record.BgPath = loadRawImage.AssetUrl
    end
    rImgBg.rectTransform.anchoredPosition3D = DefaultPos
    rImgBg.transform.localScale = DefaultScale
    AspectRatioFitter.aspectRatio = ratio
    rImgBg.gameObject:SetActiveEx(true)

    if self.NeedSupportAnim then
        rImgBg = self.UiRoot.RImgBg2
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
        self.UiRoot.RImgBg1:SetRawImage(self.BgPath)
        self.UiRoot.RImgBg2.gameObject:SetActiveEx(false)
    end
end

function XMovieActionBgSwitch:OnUndo()
    if self.Record.BgPath then
        self.UiRoot.RImgBg1:SetRawImage(self.Record.BgPath)
    end
end

return XMovieActionBgSwitch
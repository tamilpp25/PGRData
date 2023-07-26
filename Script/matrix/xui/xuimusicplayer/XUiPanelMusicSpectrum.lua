--
-- Author: wujie
-- Note: 频谱ui
---@class XUiPanelMusicSpectrum
local XUiPanelMusicSpectrum = XClass(nil, "XUiPanelMusicSpectrum")

local XMathClamp = XMath.Clamp
local SpectrumMinHeight = CS.XGame.ClientConfig:GetFloat("MusicPlayerSpectrumMinHeight")
local SpectrumBaseHeight = CS.XGame.ClientConfig:GetFloat("MusicPlayerSpectrumBaseHeight")
local SpectrumMaxHeight = CS.XGame.ClientConfig:GetFloat("MusicPlayerSpectrumMaxHeight")
local SpectrumIgnoreFrequencyCount = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIgnoreFrequencyCount")

function XUiPanelMusicSpectrum:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ImgBarRectTransformList = {
        self.ImgBarRectTransform1, self.ImgBarRectTransform2, self.ImgBarRectTransform3, self.ImgBarRectTransform4, self.ImgBarRectTransform5,
        self.ImgBarRectTransform6, self.ImgBarRectTransform7, self.ImgBarRectTransform8, self.ImgBarRectTransform9, self.ImgBarRectTransform10,
        self.ImgBarRectTransform11, self.ImgBarRectTransform12, self.ImgBarRectTransform13, self.ImgBarRectTransform14, self.ImgBarRectTransform15,
        self.ImgBarRectTransform16, self.ImgBarRectTransform17, self.ImgBarRectTransform18, self.ImgBarRectTransform19, self.ImgBarRectTransform20,
        self.ImgBarRectTransform21, self.ImgBarRectTransform22, self.ImgBarRectTransform23, self.ImgBarRectTransform24, self.ImgBarRectTransform25,
        self.ImgBarRectTransform26, self.ImgBarRectTransform27, self.ImgBarRectTransform28, self.ImgBarRectTransform29, self.ImgBarRectTransform30,
        self.ImgBarRectTransform31, self.ImgBarRectTransform32, self.ImgBarRectTransform33, self.ImgBarRectTransform34, self.ImgBarRectTransform35,
        self.ImgBarRectTransform36, self.ImgBarRectTransform37, self.ImgBarRectTransform38, self.ImgBarRectTransform39, self.ImgBarRectTransform40,
        self.ImgBarRectTransform41, self.ImgBarRectTransform42, self.ImgBarRectTransform43, self.ImgBarRectTransform44, self.ImgBarRectTransform45,
        self.ImgBarRectTransform46, self.ImgBarRectTransform47, self.ImgBarRectTransform48, self.ImgBarRectTransform49, self.ImgBarRectTransform50,
        self.ImgBarRectTransform51, self.ImgBarRectTransform52, self.ImgBarRectTransform53, self.ImgBarRectTransform54, self.ImgBarRectTransform55,
        self.ImgBarRectTransform56, self.ImgBarRectTransform57, self.ImgBarRectTransform58, self.ImgBarRectTransform59, self.ImgBarRectTransform60,
    }
end

function XUiPanelMusicSpectrum:UpdateSpectrum(spectrumData)
    local spectrumDataLength = spectrumData.Length
    local height
    for i, rectTransform in ipairs(self.ImgBarRectTransformList) do
        if i <= spectrumDataLength then
            rectTransform.gameObject:SetActiveEx(true)
            local spectrumValue = spectrumData[i+SpectrumIgnoreFrequencyCount-1] or 0
            height = XMathClamp(spectrumValue * SpectrumBaseHeight, SpectrumMinHeight, SpectrumMaxHeight)
            rectTransform:SetSizeDeltaY(height)
        else
            rectTransform.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelMusicSpectrum:CreateImgBar(instance, amount)
    amount = amount or 60
    self.ImgBarRectTransformList[1] = instance
    for i = 2, amount do
        self.ImgBarRectTransformList[i] = CS.UnityEngine.Object.Instantiate(instance, instance.transform.parent)
    end
end

function XUiPanelMusicSpectrum:Reverse()
    local amount = #self.ImgBarRectTransformList 
    for i = 1, amount/2 do
        local imgBar = self.ImgBarRectTransformList[i]
        self.ImgBarRectTransformList[i] = self.ImgBarRectTransformList[amount - i + 1]
        self.ImgBarRectTransformList[amount - i + 1] = imgBar
    end
end

return XUiPanelMusicSpectrum
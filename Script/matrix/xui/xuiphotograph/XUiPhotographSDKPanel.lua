---@class XUiPhotographSDKPanel
local XUiPhotographSDKPanel = XClass(XSignalData, "XUiPhotographSDKPanel")
local DBEUG_SHOW_CUSTOM_SHARE_TEXT = true

function XUiPhotographSDKPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiPhotographSDKPanel:Init()
    self.ShareBtnList = {
        self.BtnShare1,
        self.BtnShare2,
        self.BtnShare3,
        self.BtnShare4,
        self.BtnShare5,
    }
    self:AutoRegisterBtn()
end

function XUiPhotographSDKPanel:AutoRegisterBtn()
    local shareSDKIds = XDataCenter.PhotographManager.GetShareSDKIds()
    local shareBtnCount = #shareSDKIds
    for i=1, #self.ShareBtnList, 1 do
        if i <= shareBtnCount then
            local shareInfo = XPhotographConfigs.GetShareInfoByType(shareSDKIds[i])
            if shareInfo then
                self.ShareBtnList[i].gameObject:SetActiveEx(true)
                self.ShareBtnList[i].CallBack = function () self:OnClickShareBtn(i) end
                self.ShareBtnList[i]:SetSprite(shareInfo.IconPath)
                self.ShareBtnList[i]:SetName(shareInfo.Name)
            end
        else
            self.ShareBtnList[i].gameObject:SetActiveEx(false)
        end
    end
    self.BtnSave.CallBack = function ()
        XDataCenter.PhotographManager.SharePhoto(self.RootUi.PhotoName, self.RootUi.ShareTexture, XPlatformShareConfigs.PlatformType.Local)
    end
end

function XUiPhotographSDKPanel:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPhotographSDKPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPhotographSDKPanel:OnClickShareBtn(index)
    local platformType = XDataCenter.PhotographManager.GetShareTypeByIndex(index)
    local result = self:EmitSignal("ShareBtnClicked", platformType, self)
    if result and result.isAwait then
        RunAsyn(function()
            local signalCode = self:AwaitSignal("FinishedReadyShare", self)
            if signalCode ~= XSignalCode.SUCCESS then return end
            self:Share(platformType)
        end)
        return
    end
    self:Share(platformType)
end

function XUiPhotographSDKPanel:Share(platformType)
    local customText
    if self.RootUi.GetPlatformType2CustomText then
        customText = self.RootUi.GetPlatformType2CustomText(self.RootUi, platformType)
    end
    if DBEUG_SHOW_CUSTOM_SHARE_TEXT then
        XLog.Warning(customText or "其他系统测试分享")
    end
    XDataCenter.PhotographManager.SharePhoto(self.RootUi.PhotoName, self.RootUi.ShareTexture, platformType, customText)
end

return XUiPhotographSDKPanel
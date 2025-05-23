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
        self.BtnShare6,
        self.BtnShare7,
        self.BtnShare8,
    }
    self:AutoRegisterBtn()
end

function XUiPhotographSDKPanel:AutoRegisterBtn()
    local shareSDKIds = XDataCenter.PhotographManager.GetShareSDKIds()
    local shareBtnCount = #shareSDKIds
    
    -- 先全部隐藏
    for i, v in ipairs(self.ShareBtnList) do
        v.gameObject:SetActiveEx(false)
    end
    
    -- 逐一检测和显示开启的分享入口
    if not XTool.IsTableEmpty(shareSDKIds) then
        local btnIndex = 1

        for i, id in ipairs(shareSDKIds) do
            local shareInfo = XPhotographConfigs.GetShareInfoByType(id)
            -- 存在数据且功能开启，需要显示入口
            if shareInfo and XHeroSdkManager.SharePlatformIsEnable(shareInfo.Id) then
                if btnIndex <= shareBtnCount then
                    self.ShareBtnList[btnIndex].gameObject:SetActiveEx(true)
                    self.ShareBtnList[btnIndex].CallBack = function()
                        self:OnClickShareBtn(shareInfo.Id)
                    end
                    self.ShareBtnList[btnIndex]:SetSprite(shareInfo.IconPath)
                    self.ShareBtnList[btnIndex]:SetName(shareInfo.Name)

                    btnIndex = btnIndex + 1
                else
                    XLog.Error('有效的分享入口数量超过UI上限')
                end
            end
        end
    end
    
    self.BtnSave.CallBack = function()
        XDataCenter.PhotographManager.SharePhotoBefore(self.RootUi.PhotoName, self.RootUi.ShareTexture, XPlatformShareConfigs.PlatformType.Local)
        if self.RootUi.OnBtnSaveCallBack then
            self.RootUi:OnBtnSaveCallBack()
        end
    end
    if XDataCenter.UiPcManager.IsPc() then
        if self.BtnExplorerPc then
            self.BtnExplorerPc.gameObject:SetActiveEx(true)
            self.BtnExplorerPc.CallBack = function()
                local path = CS.XTool.GetPhotoAlbumPath()
                path = string.gsub(path, "/", "\\")
                if not CS.System.IO.Directory.Exists(path) then
                    CS.System.IO.Directory.CreateDirectory(path)
                end
                CS.UnityEngine.Application.OpenURL(path)
            end
        end
    else
        if self.BtnExplorerPc then
            self.BtnExplorerPc.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPhotographSDKPanel:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPhotographSDKPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

--shareId,shareInfo中的Id，且与枚举XEnumConst.SharePlatform对应
function XUiPhotographSDKPanel:OnClickShareBtn(shareId)
    local result = self:EmitSignal("ShareBtnClicked", shareId, self)
    if result and result.isAwait then
        RunAsyn(function()
            local signalCode = self:AwaitSignal("FinishedReadyShare", self)
            if signalCode ~= XSignalCode.SUCCESS then
                return
            end
            self:Share(shareId)
        end)
        return
    end
    self:Share(shareId)
end

function XUiPhotographSDKPanel:Share(shareId)
    local customText
    if self.RootUi.GetPlatformType2CustomText then
        customText = self.RootUi.GetPlatformType2CustomText(self.RootUi, shareId)
    end
    if DBEUG_SHOW_CUSTOM_SHARE_TEXT then
        XLog.Warning(customText or "其他系统测试分享")
    end
    XDataCenter.PhotographManager.SharePhoto(self.RootUi.PhotoName, self.RootUi.ShareTexture, shareId, customText)
end

return XUiPhotographSDKPanel
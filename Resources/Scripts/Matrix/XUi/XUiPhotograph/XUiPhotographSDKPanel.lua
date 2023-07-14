local XUiPhotographSDKPanel = XClass(nil, "XUiPhotographSDKPanel")

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
    self.BtnSave.gameObject:SetActiveEx(false) -- 日服屏蔽保存功能
end

function XUiPhotographSDKPanel:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPhotographSDKPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPhotographSDKPanel:OnClickShareBtn(index)
    local platformType = XDataCenter.PhotographManager.GetShareTypeByIndex(index)
    XDataCenter.PhotographManager.SharePhoto(self.RootUi.PhotoName, self.RootUi.ShareTexture, platformType)
end

return XUiPhotographSDKPanel
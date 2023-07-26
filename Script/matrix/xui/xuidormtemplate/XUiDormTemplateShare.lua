local XUiDormTemplateShare = XLuaUiManager.Register(XLuaUi, "UiDormTemplateShare")

function XUiDormTemplateShare:OnAwake()
    self:AddListener()
end

function XUiDormTemplateShare:OnStart(homeRoomData, texture)
    self:Init(homeRoomData, texture)
end

function XUiDormTemplateShare:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
end

function XUiDormTemplateShare:Init(homeRoomData, texture)
    self.HomeRoomData = homeRoomData
    self.ShareId = tostring(self.HomeRoomData:GetShareId())

    self.TxtEncod.text = self.ShareId
    self.TxtEncodCupture.text = self.ShareId
    self.RImgBg.texture = texture
    self.RImgBgCuptrue.texture = texture

    -- 复制ShareId 到粘贴板
    CS.XAppPlatBridge.CopyStringToClipboard(self.ShareId)
    local leftShareTime = XDormConfig.MAX_SHARE_COUNT - XDataCenter.DormManager.GetSnapshotTimes()
    local tip = CS.XTextManager.GetText("DormTemplateShareTip", leftShareTime)
    XUiManager.TipMsg(tip,XUiManager.UiTipType.Tip)
end

function XUiDormTemplateShare:OnBtnCloseClick()
    self:Close()
end

function XUiDormTemplateShare:OnBtnSaveClick()
    local camerDesc = CS.XTextManager.GetText("PremissionCameraDesc")
    local readDesc = CS.XTextManager.GetText("PremissionReadDesc")
    XPermissionManager.TryGetPermission(CS.XPermissionEnum.CAMERA, camerDesc, function(isCameraGranted, dontTip)
        if not isCameraGranted then
            XUiManager.TipText("PremissionDesc", XUiManager.UiTipType.Tip)
            return
        end

        XPermissionManager.TryGetPermission(CS.XPermissionEnum.WRITE_EXTERNAL_STORAGE, readDesc, function(isWriteGranted, dontTip)
            if not isWriteGranted then
                XUiManager.TipText("PremissionDesc", XUiManager.UiTipType.Tip)
                return
            end

            CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, self.CameraCuptrue)
            local cameraController = self.CameraCuptrue.gameObject:GetComponent(typeof(CS.XCameraController))
            local imgName = tostring(XPlayer.Id) .. self.ShareId .. XDormConfig.ShareName
            local texture = cameraController:CaptureCamera(imgName, true)
            XDataCenter.DormManager.SetLocalCaptureCache(imgName, texture)
            CS.XTool.SavePhotoAlbumImg(imgName, texture, function(errorCode)
                CsXUiManager.Instance:ChangeCanvasTypeCamera(CsXUiType.Normal, CS.XUiManager.Instance.UiCamera)
                if errorCode > 0 then
                    XUiManager.TipText("PremissionDesc", XUiManager.UiTipType.Tip)
                else
                    self:PlayAnimation("ShanShuo", function()
                        XUiManager.TipText("DormTemplateShareCuptrue", XUiManager.UiTipType.Tip)
                    end)
                end
            end)
        end)
    end)
end
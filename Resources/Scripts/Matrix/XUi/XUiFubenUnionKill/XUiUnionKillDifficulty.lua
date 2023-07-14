local XUiUnionKillDifficulty = XLuaUiManager.Register(XLuaUi, "UiUnionKillDifficulty")

function XUiUnionKillDifficulty:OnAwake()
    self.BtnBg.CallBack = function() self:OnBtnBgClick() end
    self.BtnTongBlack.CallBack = function() self:OnBtnTongBlackClick() end
    self.BtnTongBlue.CallBack = function() self:OnBtnTongBlueClick() end

end

function XUiUnionKillDifficulty:OnDestroy()
end


function XUiUnionKillDifficulty:OnStart(sectionConfig, quitCb, hardModeCb)
    self.QuitCb = quitCb
    self.HardModeCb = hardModeCb
    self.RImgBadgeShiLian:SetRawImage(sectionConfig.TrialIcon)
end

function XUiUnionKillDifficulty:OnBtnBgClick()
    self:Close()
end

function XUiUnionKillDifficulty:OnBtnTongBlackClick()
    self:Close()
    if self.QuitCb then
        self.QuitCb()
    end
end

function XUiUnionKillDifficulty:OnBtnTongBlueClick()
    self:Close()
    if self.HardModeCb then
        self.HardModeCb()
    end
end
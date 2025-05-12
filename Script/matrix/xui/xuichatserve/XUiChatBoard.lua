local XUiChatBoard = XClass(XUiNode, 'XUiChatBoard')

function XUiChatBoard:Refresh(chatBoradId, isRight)
    --还原翻转
    if self._IsMirror or self.PanelBg.transform.localScale.x < 0 then
        self.PanelBg.transform.localScale = Vector3(1, 1, 1)
        self.SubIconRoot.transform.localScale = Vector3(1, 1, 1)
    end
    self._IsMirror = false
    
    -- 对聊天框Id进行检查和处理确保有效
    chatBoradId = XTool.IsNumberValid(chatBoradId) and chatBoradId or XChatConfigs.DefaultChatBoardId

    local cfg = XChatConfigs.GetChatBoardCfgById(chatBoradId)
    
    if cfg then
        --设置底图
        if isRight then
            if cfg.ChatBoardImageRes then
                self.PanelBg:SetSprite(cfg.ChatBoardImageRes)
            else
                self.PanelBg:SetSprite(cfg.ChatBoardRes)
                --翻转
                self.PanelBg.transform.localScale = Vector3(-1, 1, 1)
                self.SubIconRoot.transform.localScale = Vector3(-1, 1, 1)
                self._IsMirror = true
            end
        else
            self.PanelBg:SetSprite(cfg.ChatBoardRes)
        end
        --设置小图标
        if cfg.LogoRes then
            self.Image.gameObject:SetActiveEx(true)
            self.Image:SetRawImage(cfg.LogoRes)
        else
            self.Image.gameObject:SetActiveEx(false)
        end
    end
end

return XUiChatBoard
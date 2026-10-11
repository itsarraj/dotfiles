-- Delete the on-disk file when a buffer is empty on save or quit (:wq, :w, :q, :q!, etc.)

local group = vim.api.nvim_create_augroup('dotfiles-delete-empty', { clear = true })

local function buf_is_empty(buf)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match('%S') then
      return false
    end
  end
  return true
end

local function delete_empty_file(buf)
  if vim.bo[buf].buftype ~= '' then
    return
  end
  if not buf_is_empty(buf) then
    return
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path == '' then
    return
  end

  path = vim.fn.fnamemodify(path, ':p')
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'file' then
    return
  end

  local ok, err = vim.uv.fs_unlink(path)
  if not ok then
    vim.notify('Could not delete empty file: ' .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify('Deleted empty file: ' .. vim.fn.fnamemodify(path, ':t'), vim.log.levels.INFO)
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  desc = 'Remove file from disk when buffer has no content',
  callback = function(args)
    delete_empty_file(args.buf)
  end,
})

vim.api.nvim_create_autocmd('BufUnload', {
  group = group,
  desc = 'Remove file from disk when unloading an empty buffer (:q, :q!, :bd, :qa, …)',
  callback = function(args)
    delete_empty_file(args.buf)
  end,
})

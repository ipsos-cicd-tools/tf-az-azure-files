cd module

failed_dirs=""

for dir in $(ls -1 -d */); do
  dir=${dir%/} # Removes trailing slash
  terraform -chdir=$dir init #> /dev/null 2>&1
  terraform -chdir=$dir validate 2>"$dir/tf_validate_$dir" #1>/dev/null
  if [ $? -ne 0 ]; then
    failed_dirs="$failed_dirs $dir"
  else
    echo "$dir has no .tf files"
  fi
done

failed_module_flag=$(echo $failed_dirs | wc -c)
if [ $failed_module_flag -gt 1 ]; then
  echo "Terraform validation failed in the following modules:"
  for failed_dir in $failed_dirs
  do
    if [ "$failed_dir" = "root" ]; then
      echo "- $failed_dir (root directory)"
      cat "tf_validate_root"
    else
      echo "- $failed_dir"
      cat "$failed_dir/tf_validate_$failed_dir"
    fi
    echo "===================================="
  done
  exit 1
else
  echo "Validation Successful"
fi
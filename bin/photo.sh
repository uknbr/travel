#  photo.sh
#  
#  Copyright 2016 Pedro Pavan <pedro.pavan@linuxmail.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  
#!/usr/bin/env bash
#===============================================================
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      02-07-2016    Initial release
#===============================================================

# =======================
#  Variables
# =======================
IMG_LABEL="http://www.MYHOST/photo"
LOG_FILE="log/photo.log"
HTML_FILE="html/photo.html"

# =======================
#  Usage
# =======================
Usage() {
	echo -e "Usage:\n"
	echo -e "$(basename $0) [-v]"
	exit 0
}

# =======================
#  Border
# =======================
Border() {
	TYPE=$1
	TIME=$(date '+%F %T')
	NEWLINE="?"
	
	echo -e "================================"
	echo -e "  ${TYPE} time - ${TIME}"
	echo -e "================================"
	
	[ "${TYPE}" == "Start" ] && NEWLINE="\n" || NEWLINE=""
	echo -e "${NEWLINE}***************** $(basename $0) [${TIME}] *****************" >> ${LOG_FILE}
}

# =======================
#  Check Softwares
# =======================
Check_SW() {
	SW_LIST="composite"
	
	for sw in $(echo ${SW_LIST} | tr ',' '\n'); do
		if [ "$(which ${sw} > /dev/null 2>&1 ; echo $?)" != "0" ]; then
			Message -fail "Missing packages, check: ${SW_LIST}"
			Exit_Script 10
		fi 
	done
}

# =======================
#  Message
# =======================
Message() {
	MSG_TYPE="$1"
	MSG="$2"
	
	case "${MSG_TYPE}" in
		"-info")	echo "[+] ${MSG}" | tee -a ${LOG_FILE}	;;
		"-fail")	echo "[!] ${MSG}" | tee -a ${LOG_FILE}	;;
		"-more")	echo "[*] ${MSG}" | tee -a ${LOG_FILE}	;;
		      *)	echo "[-] ${MSG}" | tee -a ${LOG_FILE}	;;
	esac
}

# =======================
#  Exit
# =======================
Exit_Script() {
	EXIT_CODE=$1
	
	Border "Finish"
	exit ${EXIT_CODE}
}

# =======================
#  HTML Create
# =======================
HTML_Create() {
	Message -info "Creating HTML page"
	
	rm -rf html/*
	cp -r work/* html/
	rm html/index.html
	
	cat work/photo_1.html > ${HTML_FILE}
}

# =======================
#  HTML Create
# =======================
HTML_Images() {
	Message -info "Processing images"

	TARGET_FOLDER=$(find images/ -mindepth 1 -type d | cut -d '/' -f 2)
	for folder in $(echo ${TARGET_FOLDER}); do
		mkdir -p html/img/${folder} 2> /dev/null
		echo "
				<li><a data-id=\"${folder}\" href="">${folder^}</a></li>" >> ${HTML_FILE}
	done
	
	echo "
			</ul>
		</div>
		
		<div class=\"row\">
		
		<ul class=\"thumbnails\" id=\"thumbnails\">" >> ${HTML_FILE}
	
	for folder in $(echo ${TARGET_FOLDER}); do
		FILE_COUNT=0
		echo "
			<!-- ${folder^} -->" >> ${HTML_FILE}
			
		for file in $(ls -1 images/${folder}/*); do
			FILE_COUNT=$(expr ${FILE_COUNT} + 1)
			FILE_NAME="${folder}_${FILE_COUNT}.jpg"
			echo "from: ${file} to: html/img/${folder}/${FILE_NAME}" >> ${LOG_FILE}
			cp -f ${file} html/img/${folder}/${FILE_NAME}
			composite label:"${IMG_LABEL}" html/img/${folder}/${FILE_NAME} html/img/${folder}/${FILE_NAME}
			
			echo "
			<li class=\"col-md-3 col-sm-3 col-xs-12\" data-id=\"1\" data-type=\"${folder}\">
				<a href=\"img/${folder}/${FILE_NAME}\" class=\"thumbnail\">
				  <img src=\"img/${folder}/${FILE_NAME}\" alt=\"\" />
				  <span class=\"caption\"><i class=\"icon-plus-sign\"></i></span>
				</a>
			</li>
			" >> ${HTML_FILE}
		done
	done
}

# =======================
#  HTML End
# =======================
HTML_End() {
	Message -info "Finishing HTML page"
	cat work/photo_2.html >> ${HTML_FILE}
	
	cd html
	ln -sf $(echo ${HTML_FILE} | awk -F '/' '{ print $NF }') index.html
	cd - > /dev/null 2>&1	
}

# =======================
#  HTML Deploy
# =======================
HTML_Deploy() {
	Message -info "Creating deploy package"
	PACKAGE_FILE="deploy/photo.tar.gz"
	rm -f ${PACKAGE_FILE} 2> /dev/null
	cp -a html/ photo/
	tar -czvf ${PACKAGE_FILE} photo/ >> ${LOG_FILE} 2>&1
	rm -rf photo/
}

# =======================
#  Statistics
# =======================
Statistics() {
	STAT_FILES=$(find images/ -type f | wc -l)
	STAT_SIZE=$(ls -lhr deploy/ | tail -1 | awk '{ print $5 }')
	Message -info "Statistics: Files = ${STAT_FILES} | Size = ${STAT_SIZE}"
}

# =======================
#  MAIN
# =======================
cd ../
> ${LOG_FILE}

Border "Start"

Check_SW

HTML_Create

HTML_Images

HTML_End

HTML_Deploy

Statistics

Exit_Script 0

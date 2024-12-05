//  SPDX-FileCopyrightText: 2024-2024 OOMOL, Inc. <https://www.oomol.com>
//  SPDX-License-Identifier: MPL-2.0

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"github.com/sirupsen/logrus"
	"os"
	"path/filepath"
	"strings"
)

type MountPoint struct {
	HostPath         string `json:"hostPath"`
	ContainerPath    string `json:"containerPath"`
	ContainerDirName string `json:"containerDirName"`
	Undeletable      bool   `json:"undeletable,omitempty"`
}

type DataStruct struct {
	MountPoints       []MountPoint `json:"mountPoints"`
	CurrentMountPoint MountPoint   `json:"currentMountPoint"`
}

const (
	subtitlesPrefix           = "subtitles="
	oomolStorage              = "/oomol-driver/oomol-storage" // Must not end with '/'
	oomolStorageWithSubtitles = subtitlesPrefix + oomolStorage
)

func ContainerPath2HostPath(arg string, jsonData *DataStruct) string {
	logrus.Infof("Process string: %s", arg)
	// if prefix with  "subtitles=/oomol-driver/oomol-storage"
	if strings.HasPrefix(arg, oomolStorage) {
		homeDir, _ := os.UserHomeDir()
		p := filepath.Join(homeDir, "oomol-storage")
		_arg := strings.Replace(arg, oomolStorage, p, 1)
		logrus.Warnf("%s --> %s \n", arg, _arg)
		return _arg
	}

	// if prefix with  "subtitles=/oomol-driver/oomol-storage"
	if strings.HasPrefix(arg, oomolStorageWithSubtitles) {
		homeDir, _ := os.UserHomeDir()
		p := filepath.Join(homeDir, "oomol-storage")
		_arg := strings.Replace(arg, oomolStorage, p, 1)
		logrus.Warnf("%s --> %s \n", arg, _arg)
		return _arg
	}

	for _, mountPoint := range jsonData.MountPoints {
		// Check if the argument starts with the mountPoint.ContainerPath the replace
		if strings.HasPrefix(arg, mountPoint.ContainerPath) {
			_arg := strings.Replace(arg, mountPoint.ContainerPath, mountPoint.HostPath, 1)
			logrus.Warnf("%s --> %s \n", arg, _arg)
			return _arg
		}
		if strings.HasPrefix(arg, subtitlesPrefix+mountPoint.ContainerPath) {
			_arg := strings.Replace(arg, mountPoint.ContainerPath, mountPoint.HostPath, 1)
			logrus.Warnf("%s --> %s \n", arg, _arg)
			return _arg
		}
	}
	return arg
}

// loadJson loads the mount-point.json file from the given path using json.Unmarshal
func loadJson(path string) (*DataStruct, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var data DataStruct
	decoder := json.NewDecoder(file)
	if err = decoder.Decode(&data); err != nil {
		return nil, err
	}
	return &data, nil
}

// format output
func outNewCmdLine(newArgs []string) {
	fmt.Printf("NEW_CMELINE:")
	for _, arg := range newArgs {
		fmt.Printf("%s ", arg)
	}
	fmt.Printf("\n")
}

func main() {
	flag.Parse()
	logrus.Infof("Arguments: %v", flag.Args())

	homeDir, _ := os.UserHomeDir()
	jsonData, err := loadJson(filepath.Join(homeDir, ".oomol-studio", "app-config", "oomol-storage", "mount-point.json"))
	if err != nil {
		logrus.Errorf("Failed to load mount-point.json: %v", err)
		return
	}

	newArgs := make([]string, 0)
	for _, arg := range flag.Args() {
		argCovered := ContainerPath2HostPath(arg, jsonData)
		newArgs = append(newArgs, argCovered)
	}

	outNewCmdLine(newArgs)

}


//  SPDX-FileCopyrightText: 2024-2025 OOMOL, Inc. <https://www.oomol.com>
//  SPDX-License-Identifier: MPL-2.0

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"github.com/sirupsen/logrus"
	"os"
	"os/exec"
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
	oomolStorage  = "/oomol-driver/oomol-storage"
	oomolSessions = "/oomol-driver/sessions"
)

func ContainerPath2HostPath(arg string, jsonData *DataStruct) string {
	logrus.Infof("Process string: %q", arg)

	// if prefix with  "subtitles=/oomol-driver/oomol-storage"
	if strings.Contains(arg, oomolSessions) {
		homeDir, _ := os.UserHomeDir()
		p := filepath.Join(homeDir, ".oomol-studio", "sessions")
		_arg := strings.Replace(arg, oomolSessions, p, 1)
		logrus.Infof("%q --> %q \n", arg, _arg)
		return _arg
	}

	// if prefix with  "subtitles=/oomol-driver/oomol-storage"
	if strings.Contains(arg, oomolStorage) {
		homeDir, _ := os.UserHomeDir()
		p := filepath.Join(homeDir, "oomol-storage")
		_arg := strings.Replace(arg, oomolStorage, p, 1)
		logrus.Infof("%q --> %q \n", arg, _arg)
		return _arg
	}

	if jsonData != nil {
		for _, mountPoint := range jsonData.MountPoints {
			// Check if the argument starts with the mountPoint.ContainerPath the replace
			if strings.Contains(arg, mountPoint.ContainerPath) {
				_arg := strings.Replace(arg, mountPoint.ContainerPath, mountPoint.HostPath, 1)
				logrus.Infof("%q --> %q \n", arg, _arg)
				return _arg
			}
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
func outNewCmdLine(newArgs []string) []string {
	processedArgs := make([]string, 0)
	for _, arg := range newArgs {
		processedArgs = append(processedArgs, fmt.Sprintf("%s", arg))
	}
	logrus.Infof("Build commandline: %s", strings.Join(processedArgs, " "))
	return processedArgs
}

func doExec(processedArgs []string) error {
	executable, err := os.Executable()
	if err != nil {
		logrus.Errorf("Failed to get executable path: %v", err)
		return err
	}
	logrus.Infof("Workdir: %s", filepath.Dir(executable))

	targetBin := filepath.Join(filepath.Dir(executable), "bin", processedArgs[0])
	cmd := exec.Command("chmod", "+x", targetBin)
	logrus.Infof("Run chmod command: %q", cmd.Args)
	err = cmd.Run()
	if err != nil {
		logrus.Errorf("Failed to run %q: %v\n", cmd.Args, err.Error())
		return err
	}

	cmd = exec.Command(targetBin, processedArgs[1:]...)
	cmd.Env = os.Environ()
	searchLibsDir := filepath.Dir(executable) + "/lib"
	logrus.Infof("set DYLD_LIBRARY_PATH: %q", searchLibsDir)
	cmd.Env = append(cmd.Env, "DYLD_LIBRARY_PATH="+searchLibsDir)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	logrus.Infof("Run command line: %q", cmd.Args)
	err = cmd.Run()
	if err != nil {
		logrus.Errorf("Failed to run %q: %v\n", cmd.Args, err.Error())
		return err
	}

	return nil
}

func init() {
	logrus.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
		ForceColors:   true,
	})
	logrus.SetLevel(logrus.InfoLevel)

	executable, err := os.Executable()
	if err != nil {
		logrus.Fatalf("Failed to get executable path: %v", err)
	}

	err = os.Chdir(filepath.Dir(executable))
	if err != nil {
		logrus.Fatalf("Failed to change workdir: %v", err)
	}
	file, err := os.OpenFile("exec_log.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		logrus.Fatalf("Failed to open log file: %v", err)
	}
	logrus.SetOutput(file)
}

func main() {
	flag.Parse()

	if len(flag.Args()) == 0 {
		logrus.Errorf("No arguments provided")
		os.Exit(128)
	}

	logrus.Infof("Arguments: %q", flag.Args())

	homeDir, _ := os.UserHomeDir()
	jsonData, err := loadJson(filepath.Join(homeDir, ".oomol-studio", "app-config", "oomol-storage", "mount-point.json"))
	if err != nil {
		logrus.Warnf("Failed to load mount-point.json: %v", err)
	}

	newArgs := make([]string, 0)
	for _, arg := range flag.Args() {
		argCovered := ContainerPath2HostPath(arg, jsonData)
		newArgs = append(newArgs, argCovered)
	}

	processedArgs := outNewCmdLine(newArgs)
	err = doExec(processedArgs)
	if err != nil {
		logrus.Errorf("Failed to doExec: %v", err)
		os.Exit(1)
	}
}

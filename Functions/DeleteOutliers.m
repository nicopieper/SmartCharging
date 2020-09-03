function Mat=DeleteOutliers(Mat, Fac)
    Mat(Mat>mean(Mat*Fac))=0;
end